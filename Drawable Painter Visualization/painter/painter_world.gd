class_name PainterWorld
extends Node3D
## drawable-textures 페인터 데모 이식본의 얇은 API 계층.
##
## 원본 main.tscn의 무대(환경·조명·바닥·인형)와 컴포넌트 3종(캔버스·피커·
## 브러시)을 코드로 조립하고, 챕터들이 노드 경로를 몰라도 쓸 수 있는 메서드를
## 제공한다. 파워워시 모드(때 마스크)는 챕터 5가 요청할 때 지연 생성한다.
##
## 화면 좌표 헬퍼는 전부 0~1 정규화 좌표를 받는다 — 카메라를 먼저 두고
## 레이캐스트로 UV를 얻으므로, "보이는 면에" 결정적으로 칠할 수 있다.

const PaintCanvasComponent := preload("res://painter/scripts/paint_canvas_component.gd")
const SurfacePickerComponent := preload("res://painter/scripts/surface_picker_component.gd")
const BrushComponent := preload("res://painter/scripts/brush_component.gd")
const DirtCanvasComponent := preload("res://painter/scripts/dirt_canvas_component.gd")
const ProgressComponent := preload("res://painter/scripts/progress_component.gd")

const DRAW_SHADER := preload("res://painter/shaders/draw.gdshader")
const DIRT_SURFACE_SHADER := preload("res://painter/shaders/dirt_surface.gdshader")
const PLUSHY_SCENE := preload("res://painter/assets/Plushy-Unique-UVs.glb")

const TEX_PLUSH_ALBEDO := preload("res://painter/assets/textures/godot_plush_basecolor.png")
const TEX_PLUSH_NORMAL := preload("res://painter/assets/textures/godot_plush_normal.png")
const TEX_PLUSH_ROUGHNESS := preload("res://painter/assets/textures/godot_plush_roughness.png")
const TEX_STONE_ALBEDO := preload("res://painter/assets/textures/Metal062C_2K-JPG_Color.jpg")
const TEX_STONE_NORMAL := preload("res://painter/assets/textures/Metal062C_2K-JPG_NormalGL.jpg")
const TEX_STONE_METALNESS := preload("res://painter/assets/textures/Metal062C_2K-JPG_Metalness.jpg")
const TEX_STONE_ROUGHNESS := preload("res://painter/assets/textures/Metal062C_2K-JPG_Roughness.jpg")

## 원본 main.tscn과 같은 값들.
const TEXTURE_SIZE := Vector2i(1024, 1024)
const DRAW_SIZE_MIN := 8.0
const DRAW_SIZE_MAX := 512.0
const MASK_SCALE_MAX := 5.0
const STEPS_PER_UV_UNIT := 100

var draw_material: ShaderMaterial
var canvas: PaintCanvasComponent
var picker: SurfacePickerComponent
var brush: BrushComponent
var dirt_canvas: DirtCanvasComponent
var progress: ProgressComponent

var camera_rig: OrbitCamera
var mesh: MeshInstance3D
var world_environment: WorldEnvironment

## true면 LMB 드래그가 인형 위에서는 칠하기, 빗나가면 궤도 회전이 된다.
var interactive := false

var _orm_material: ORMMaterial3D
var _original_material: ORMMaterial3D
var _dirt_material: ShaderMaterial
var _albedo_tex: DrawableTexture2D
var _normal_tex: DrawableTexture2D
var _orm_tex: DrawableTexture2D

var _brushes: Array[BrushSet] = []
var _masks: Array[BrushMask] = []
var _nozzle: NozzlePreset

var _view_yaw := PI
var _view_pitch := -0.18
var _view_dist := 0.32

var _stroking := false
var _orbiting := false
var _last_uv = null
var _spray_last_world := Vector3.ZERO
var _spraying := false
var _uv_to_world_scale := 1.0


func _ready() -> void:
	_build_stage()
	_build_camera()
	_build_components()
	use_paint_canvas()


func environment() -> Environment:
	return world_environment.environment


func set_view(yaw: float, pitch: float, dist: float) -> void:
	_view_yaw = yaw
	_view_pitch = pitch
	_view_dist = dist
	camera_rig.set_view(yaw, pitch, dist)


func camera() -> Camera3D:
	return camera_rig.get_node("Camera3D") as Camera3D


# ---------------------------------------------------------------- 무대 조립 --

func _build_stage() -> void:
	# 환경: 원본 main.tscn의 Environment 값 이식.
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.332, 0.728, 1.0)
	sky_material.sky_horizon_color = Color(0.453, 0.49, 0.468)
	sky_material.sky_curve = 0.0097
	sky_material.ground_bottom_color = Color(0.192, 0.22, 0.194)
	sky_material.ground_horizon_color = Color(0.455, 0.49, 0.467)
	sky_material.ground_curve = 0.155
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(0.852, 0.852, 0.852)
	env.ambient_light_sky_contribution = 0.83
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.45
	env.ssao_enabled = true
	env.ssao_radius = 0.08
	env.ssao_intensity = 4.72
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.adjustment_enabled = true
	env.adjustment_contrast = 0.8
	env.adjustment_saturation = 1.2
	world_environment = WorldEnvironment.new()
	world_environment.environment = env
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.865, 0.829, 0.72)
	sun.light_energy = 0.5
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-50.0, -150.0, 0.0)
	add_child(sun)

	# 원본의 3점 보조 옴니 라이트.
	for setup: Array in [
		[Vector3(0.0, 0.26, 0.45), Color(0.944, 0.739, 0.37)],
		[Vector3(0.41, 0.26, -0.21), Color(0.95, 0.589, 0.727)],
		[Vector3(-0.44, 0.27, -0.21), Color(0.667, 0.949, 0.739)],
	]:
		var omni := OmniLight3D.new()
		omni.position = setup[0]
		omni.light_color = setup[1]
		omni.light_energy = 0.2
		omni.omni_attenuation = 2.0
		add_child(omni)

	# 바닥: 가장자리로 투명해지는 원형 그라데이션 플레인.
	var floor_gradient := Gradient.new()
	floor_gradient.offsets = PackedFloat32Array([0.919, 1.0])
	floor_gradient.colors = PackedColorArray([
		Color(0.687, 0.687, 0.687, 1.0), Color(0.69, 0.69, 0.69, 0.0)])
	var floor_texture := GradientTexture2D.new()
	floor_texture.gradient = floor_gradient
	floor_texture.width = 256
	floor_texture.height = 256
	floor_texture.fill = GradientTexture2D.FILL_RADIAL
	floor_texture.fill_from = Vector2(0.5, 0.5)
	floor_texture.fill_to = Vector2(1.0, 0.5)
	var floor_material := StandardMaterial3D.new()
	floor_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	floor_material.alpha_scissor_threshold = 0.5
	floor_material.albedo_texture = floor_texture
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.position.y = -0.055
	floor_mesh.set_surface_override_material(0, floor_material)
	add_child(floor_mesh)

	# 인형: 고유 UV로 다시 펼친 Godot 플러시.
	var plushy := PLUSHY_SCENE.instantiate() as Node3D
	plushy.position.y = -0.0531
	add_child(plushy)
	mesh = plushy.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D


func _build_camera() -> void:
	# 인형 AABB가 높이 0.15m, 월드 중심 y≈0.02라 피벗과 거리를 그에 맞춘다.
	camera_rig = OrbitCamera.new()
	camera_rig.min_distance = 0.08
	camera_rig.max_distance = 3.0
	camera_rig.position = Vector3(0.0, 0.02, 0.0)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.near = 0.005
	cam.far = 100.0
	camera_rig.add_child(cam)
	add_child(camera_rig)
	camera_rig.set_view(_view_yaw, _view_pitch, _view_dist)


func _build_components() -> void:
	draw_material = ShaderMaterial.new()
	draw_material.shader = DRAW_SHADER

	canvas = _add_component(PaintCanvasComponent, "PaintCanvas") as PaintCanvasComponent
	picker = _add_component(SurfacePickerComponent, "SurfacePicker") as SurfacePickerComponent
	brush = _add_component(BrushComponent, "Brush") as BrushComponent

	_albedo_tex = DrawableTexture2D.new()
	_normal_tex = DrawableTexture2D.new()
	_orm_tex = DrawableTexture2D.new()
	_orm_material = ORMMaterial3D.new()
	_orm_material.albedo_texture = _albedo_tex
	_orm_material.normal_enabled = true
	_orm_material.normal_texture = _normal_tex
	_orm_material.orm_texture = _orm_tex

	picker.setup(mesh)
	_uv_to_world_scale = picker.get_uv_to_world_scale()

	brush.setup(draw_material, brushes(), masks(),
			DRAW_SIZE_MIN, DRAW_SIZE_MAX, MASK_SCALE_MAX)
	brush.set_brush(0)
	brush.set_mask(0)
	brush.set_size(128.0)
	brush.set_opacity(1.0)
	brush.set_mask_scale(1.0)


func _add_component(script: Script, node_name: String) -> Node:
	var instance: Node = script.new()
	instance.name = node_name
	add_child(instance)
	return instance


# ------------------------------------------------------------ 표면 모드 전환 --

## 그릴 수 있는 캔버스 모드. 부를 때마다 세 장을 초기색으로 되돌린다 —
## apply_step이 스텝마다 상태를 처음부터 다시 만들 수 있도록.
func use_paint_canvas() -> void:
	mesh.material_override = _orm_material
	canvas.setup(mesh, TEXTURE_SIZE, draw_material)
	draw_material.set_shader_parameter("debug_mode", 0)
	draw_material.set_shader_parameter("maskRotation", 0.0)
	draw_material.set_shader_parameter("maskOffset", Vector2.ZERO)
	_last_uv = null


## 원본 인형 텍스처(정적 ImageTexture) 모드 — "그릴 수 없는" 비교 기준.
func use_original_textures() -> void:
	if _original_material == null:
		_original_material = ORMMaterial3D.new()
		_original_material.albedo_texture = TEX_PLUSH_ALBEDO
		_original_material.normal_enabled = true
		_original_material.normal_texture = TEX_PLUSH_NORMAL
	mesh.material_override = _original_material


## 파워워시 모드: dirt_surface 셰이더 + 때 마스크. 부를 때마다 마스크를
## 초기 얼룩 패턴으로 리셋한다. build_coverage는 비싸서 옵션으로 뒀다.
func use_dirt_surface(with_coverage := false) -> void:
	_dirt_material = ShaderMaterial.new()
	_dirt_material.shader = DIRT_SURFACE_SHADER
	_dirt_material.set_shader_parameter("clean_albedo", TEX_PLUSH_ALBEDO)
	_dirt_material.set_shader_parameter("clean_normal", TEX_PLUSH_NORMAL)
	_dirt_material.set_shader_parameter("clean_roughness", TEX_PLUSH_ROUGHNESS)
	_dirt_material.set_shader_parameter("dirt_color", Color(0.12, 0.09, 0.05))
	_dirt_material.set_shader_parameter("dirt_roughness", 0.95)
	# 원본 powerwash_main.tscn과 같은 초기 얼룩: 금속 텍스처의 R채널.
	_dirt_material.set_shader_parameter("dirt_mask", TEX_STONE_METALNESS)
	mesh.material_override = _dirt_material

	if dirt_canvas == null:
		dirt_canvas = _add_component(DirtCanvasComponent, "DirtCanvas") as DirtCanvasComponent
		progress = _add_component(ProgressComponent, "Progress") as ProgressComponent
	dirt_canvas.setup(mesh, TEXTURE_SIZE, null)
	if with_coverage:
		dirt_canvas.build_coverage(picker.get_all_triangles())
	progress.setup(dirt_canvas.get_dirt_mask())
	if with_coverage:
		progress.set_coverage_mask(dirt_canvas.get_coverage_mask())
	_spraying = false


func nozzle() -> NozzlePreset:
	if _nozzle == null:
		_nozzle = NozzlePreset.new()
		_nozzle.nozzle_label = "15° Medium"
		_nozzle.spray_size_px = 64.0
		_nozzle.pressure = 0.7
	return _nozzle


# ------------------------------------------------------------ 브러시·마스크 --

func brushes() -> Array[BrushSet]:
	if not _brushes.is_empty():
		return _brushes
	var stone := BrushSet.new()
	stone.brush_label = "Stone"
	stone.albedo_texture = TEX_STONE_ALBEDO
	stone.normal_texture = TEX_STONE_NORMAL
	stone.occlusion_texture = TEX_STONE_METALNESS
	stone.roughness_texture = TEX_STONE_ROUGHNESS
	stone.metallic_texture = TEX_STONE_METALNESS
	var godot := BrushSet.new()
	godot.brush_label = "Godot"
	godot.albedo_texture = TEX_PLUSH_ALBEDO
	godot.normal_texture = TEX_PLUSH_NORMAL
	godot.occlusion_texture = _flat_texture(Color.WHITE)
	godot.roughness_texture = _flat_texture(Color(0.75, 0.75, 0.75))
	godot.metallic_texture = TEX_PLUSH_ROUGHNESS
	_brushes = [stone, godot]
	return _brushes


func masks() -> Array[BrushMask]:
	if not _masks.is_empty():
		return _masks
	var none := BrushMask.new()
	none.mask_label = "No Mask"
	none.mask_texture = _flat_texture(Color.WHITE)
	var perlin := BrushMask.new()
	perlin.mask_label = "Perlin Noise"
	perlin.mask_texture = _noise_texture(FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 0.0328)
	var voronoi := BrushMask.new()
	voronoi.mask_label = "Voronoi Noise"
	voronoi.mask_texture = _noise_texture(FastNoiseLite.TYPE_CELLULAR, 0.0528)
	_masks = [none, perlin, voronoi]
	return _masks


func _flat_texture(color: Color) -> ImageTexture:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## NoiseTexture2D는 스레드로 구워져 첫 프레임엔 비어 있다. 오토투어가
## 빈 마스크를 찍지 않도록 동기 생성되는 이미지로 만든다.
func _noise_texture(noise_type: int, frequency: float) -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.noise_type = noise_type as FastNoiseLite.NoiseType
	noise.frequency = frequency
	noise.seed = 7
	if noise_type == FastNoiseLite.TYPE_CELLULAR:
		noise.fractal_octaves = 2
		noise.fractal_gain = 1.229
	return ImageTexture.create_from_image(noise.get_seamless_image(512, 512))


func get_albedo_texture() -> Texture2D:
	return _albedo_tex


func get_normal_texture() -> Texture2D:
	return _normal_tex


func get_orm_texture() -> Texture2D:
	return _orm_tex


# ---------------------------------------------------- 화면 좌표 페인트 헬퍼 --

func screen_px(normalized: Vector2) -> Vector2:
	return normalized * Vector2(get_viewport().get_visible_rect().size)


## 정규화 화면 좌표의 레이캐스트 UV. 빗나가면 null.
func uv_at(normalized: Vector2):
	return picker.get_uv(camera(), screen_px(normalized))


func hit_at(normalized: Vector2):
	return picker.get_hit_info(camera(), screen_px(normalized))


## 화면 위 한 점에 스탬프 한 방.
func stamp_at(normalized: Vector2, size_px: float, brush_set: BrushSet) -> void:
	var uv = uv_at(normalized)
	if uv != null:
		canvas.paint_at(uv, size_px, brush_set)


## 화면 좌표 점 목록을 따라 잇는 스트로크. per_event=true면 점마다 단발
## 스탬프(끊긴 자국), false면 paint_segment 보간(연속 자국).
func paint_screen_path(points: Array[Vector2], size_px: float, brush_set: BrushSet,
		per_event := false, steps_per_uv_unit := STEPS_PER_UV_UNIT) -> void:
	var previous = null
	for point in points:
		var uv = uv_at(point)
		if uv == null:
			previous = null
			continue
		if per_event or previous == null:
			canvas.paint_at(uv, size_px, brush_set)
		else:
			canvas.paint_segment(previous, uv, steps_per_uv_unit, size_px, brush_set)
		previous = uv


## 두 점 사이를 부드러운 호로 샘플링한 화면 경로.
func arc_path(from_n: Vector2, to_n: Vector2, samples: int, bulge := 0.06) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var point := from_n.lerp(to_n, t)
		point.y -= sin(t * PI) * bulge
		points.append(point)
	return points


## 파워워시: 화면 경로를 따라 3D 캡슐 지우기(원본 _spray 로직 이식).
func spray_screen_path(points: Array[Vector2], spray_size_px := -1.0) -> void:
	var size_px := spray_size_px if spray_size_px > 0.0 else nozzle().spray_size_px
	var uv_radius := (size_px * 0.5) / float(TEXTURE_SIZE.x)
	var radius := uv_radius * _uv_to_world_scale
	var last_world = null
	for point in points:
		var hit = picker.get_uv_and_world(camera(), screen_px(point))
		if hit == null:
			last_world = null
			continue
		var from_world: Vector3 = hit.world_pos if last_world == null else last_world
		last_world = hit.world_pos
		_erase_capsule(from_world, hit.world_pos, radius)


func _erase_capsule(from_world: Vector3, to_world: Vector3, radius: float) -> void:
	var triangles := picker.get_triangles_in_capsule(from_world, to_world, radius)
	var inverse := mesh.global_transform.inverse()
	var model_scale: float = mesh.global_basis.get_scale().x
	dirt_canvas.erase_at_3d(
			inverse * from_world, inverse * to_world,
			radius / maxf(model_scale, 1e-6), triangles, nozzle())


# ------------------------------------------------------------ 직접 그리기 --

func set_interactive(enabled: bool) -> void:
	interactive = enabled
	# 켜면 궤도 회전을 이 스크립트가 대신 맡는다(맞으면 칠하고 빗나가면 회전).
	camera_rig.set_process_unhandled_input(not enabled)


func _unhandled_input(event: InputEvent) -> void:
	if not interactive:
		return

	var button := event as InputEventMouseButton
	if button != null:
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			_view_dist = clampf(_view_dist / 1.12, camera_rig.min_distance, camera_rig.max_distance)
			camera_rig.set_view(_view_yaw, _view_pitch, _view_dist)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			_view_dist = clampf(_view_dist * 1.12, camera_rig.min_distance, camera_rig.max_distance)
			camera_rig.set_view(_view_yaw, _view_pitch, _view_dist)
		elif button.button_index == MOUSE_BUTTON_LEFT:
			_stroking = false
			_orbiting = false
			_last_uv = null
			_spraying = false
			if button.pressed:
				if _try_paint(button.position, true):
					_stroking = true
				else:
					_orbiting = true
		return

	var motion := event as InputEventMouseMotion
	if motion == null or (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
		return
	if _stroking:
		_try_paint(motion.position, false)
	elif _orbiting:
		_view_yaw = wrapf(_view_yaw - motion.relative.x * 0.006, -TAU, TAU)
		_view_pitch = clampf(_view_pitch - motion.relative.y * 0.006, -1.35, -0.06)
		camera_rig.set_view(_view_yaw, _view_pitch, _view_dist)


## 마우스 위치에 칠하기. 파워워시 모드면 지우개, 아니면 현재 브러시.
func _try_paint(position_px: Vector2, is_press: bool) -> bool:
	if mesh.material_override == _dirt_material and dirt_canvas != null:
		var hit = picker.get_uv_and_world(camera(), position_px)
		if hit == null:
			_spraying = false
			return false
		var uv_radius := (nozzle().spray_size_px * 0.5) / float(TEXTURE_SIZE.x)
		var radius := uv_radius * _uv_to_world_scale
		var from_world: Vector3 = hit.world_pos if not _spraying else _spray_last_world
		_spraying = true
		_spray_last_world = hit.world_pos
		_erase_capsule(from_world, hit.world_pos, radius)
		return true

	var uv = picker.get_uv(camera(), position_px)
	if uv == null:
		_last_uv = null
		return false
	if is_press:
		brush.randomize_mask_transform()
	var from_uv: Vector2 = uv if _last_uv == null else _last_uv
	_last_uv = uv
	canvas.paint_segment(from_uv, uv, STEPS_PER_UV_UNIT,
			brush.draw_size, brush.get_current_brush())
	return true
