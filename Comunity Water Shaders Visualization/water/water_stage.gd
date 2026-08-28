class_name WaterStage
extends Node3D
## 해부 대상 무대. 원본 갤러리(scripts/water_gallery.gd)의 규칙을 그대로 지킨다:
## [b]조명·하늘·바닥·프로브 궤도가 전부 공유된다.[/b] 그래서 칸과 칸 사이에
## 보이는 차이는 전부 셰이더 차이다.
##
## 챕터는 show_plots()로 "이번에 나란히 놓을 셰이더"만 고르면 된다. 배치·이름표·
## 포말 마스크 뷰포트·프로브 급전은 여기서 처리한다.
##
## 태양 각도는 임의로 고른 값이 아니다. 1번의 서명은 pow(NdotH, 324)짜리 아주
## 좁은 스펙큘러라, 해의 반사 경로가 화면 안에 들어와야 그 픽셀 반짝임이 보인다.
## 카메라 반대 방위·고도 28도가 그 경로를 화면에 넣는 각도다.

const PLOT_SIZE := 30.0
const SPACING := 34.0
const DETAIL_SUBDIV := 96
const OVERVIEW_SUBDIV := 40
const FOAM_LAYER := 2
const FOAM_MASK_SIZE := 256

var camera_rig: OrbitCamera
var plots: Array[WaterPlot] = []

var _elapsed := 0.0
var _plots_root: Node3D
var _environment: Environment
var _sun: DirectionalLight3D
var _camera: Camera3D
var _dive_rig: DiveRig
var _foam_viewport: SubViewport
var _foam_camera: Camera3D
var _foam_plot: WaterPlot
var _canvas_layer: CanvasLayer
var _canvas_rect: ColorRect
var _canvas_backdrop: ColorRect
var _postfx_layer: CanvasLayer
var _postfx_rect: ColorRect
var _spec_key := ""


func _ready() -> void:
	_build_environment()
	_build_foam_viewport()
	_build_camera()
	_build_layers()
	_plots_root = Node3D.new()
	_plots_root.name = "Plots"
	add_child(_plots_root)


func _process(delta: float) -> void:
	_elapsed += delta
	for plot: WaterPlot in plots:
		plot.advance(_elapsed)
	# 마스크 카메라는 칸을 따라다녀야 한다. 칸 배치는 시점에 맞춰 통째로 돌기
	# 때문에(frame 참고) 미리 계산해 둘 수가 없다.
	if _foam_plot != null and is_instance_valid(_foam_plot):
		_foam_camera.position = Vector3(
				_foam_plot.global_position.x, 24.0, _foam_plot.global_position.z)
	if not plots.is_empty():
		RenderingServer.global_shader_parameter_set(
				&"player_position", plots[0].probe.global_position)


# --- 환경 --------------------------------------------------------------------

func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.30, 0.50, 0.78)
	sky_material.sky_horizon_color = Color(0.72, 0.80, 0.86)
	sky_material.ground_bottom_color = Color(0.18, 0.20, 0.22)
	sky_material.ground_horizon_color = Color(0.55, 0.56, 0.55)
	sky_material.sun_angle_max = 12.0

	var sky := Sky.new()
	sky.sky_material = sky_material

	_environment = Environment.new()
	_environment.background_mode = Environment.BG_SKY
	_environment.sky = sky
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_energy = 1.0
	_environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	_environment.ssao_enabled = true

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = _environment
	add_child(world_env)

	_sun = DirectionalLight3D.new()
	_sun.name = "Sun"
	_sun.rotation_degrees = Vector3(-28.0, 145.0, 0.0)
	_sun.light_energy = 1.15
	_sun.shadow_enabled = true
	add_child(_sun)


func _build_camera() -> void:
	camera_rig = OrbitCamera.new()
	camera_rig.name = "CameraRig"
	camera_rig.max_distance = 400.0
	camera_rig.min_distance = 6.0
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.far = 900.0
	# 포말 블롭은 마스크 카메라만 봐야 한다.
	_camera.cull_mask = 1
	camera_rig.add_child(_camera)
	add_child(camera_rig)
	camera_rig.set_view(0.0, -0.5, 70.0)

	_dive_rig = DiveRig.new()
	_dive_rig.name = "DiveRig"
	add_child(_dive_rig)


## 01번이 요구하는 "위에서 내려본 마스크". 같은 World3D를 FOAM_LAYER만 보는
## 직교 카메라로 한 번 더 그리면 검은 배경 위 흰 원반이 그대로 나온다.
func _build_foam_viewport() -> void:
	_foam_viewport = SubViewport.new()
	_foam_viewport.name = "FoamMaskViewport"
	_foam_viewport.size = Vector2i(FOAM_MASK_SIZE, FOAM_MASK_SIZE)
	_foam_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_foam_viewport.transparent_bg = false
	# 이 뷰포트는 무대와 같은 World3D를 봐야 한다. own_world_3d를 켜면 빈 검은
	# 화면만 나온다.
	_foam_viewport.world_3d = get_world_3d()
	add_child(_foam_viewport)

	var black := Environment.new()
	black.background_mode = Environment.BG_COLOR
	black.background_color = Color.BLACK
	black.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED

	_foam_camera = Camera3D.new()
	_foam_camera.name = "FoamCamera"
	_foam_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_foam_camera.size = PLOT_SIZE
	_foam_camera.position = Vector3(0.0, 24.0, 0.0)
	_foam_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_foam_camera.cull_mask = 1 << (FOAM_LAYER - 1)
	_foam_camera.environment = black
	_foam_camera.current = true
	_foam_viewport.add_child(_foam_camera)


func _build_layers() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "Canvas2D"
	_canvas_layer.layer = 0
	add_child(_canvas_layer)

	_canvas_backdrop = ColorRect.new()
	_canvas_backdrop.color = Color(0.05, 0.06, 0.09)
	_canvas_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_canvas_backdrop)

	_canvas_rect = ColorRect.new()
	_canvas_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_canvas_rect)
	_canvas_layer.visible = false

	_postfx_layer = CanvasLayer.new()
	_postfx_layer.name = "PostFX"
	_postfx_layer.layer = 1
	add_child(_postfx_layer)

	_postfx_rect = ColorRect.new()
	_postfx_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_postfx_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_postfx_layer.add_child(_postfx_rect)
	_postfx_layer.visible = false


# --- 챕터가 쓰는 API ---------------------------------------------------------

## 나란히 놓을 셰이더를 고른다. 원소는 id(int) 또는 spec 딕셔너리
## {id, params, textures, shader, mesh, label, backdrop}. 순서가 곧 왼쪽→오른쪽.
func show_plots(specs: Array) -> void:
	# JSON은 Vector4·StringName을 못 담는다. spec에는 둘 다 들어오므로 str()로
	# 지문을 만든다 — 같은 스텝을 다시 그릴 때 다시 짓지 않기 위한 용도일 뿐이다.
	var key := str(specs)
	if key == _spec_key:
		return
	_spec_key = key
	_foam_plot = null
	for plot: WaterPlot in plots:
		plot.queue_free()
	plots.clear()

	var subdiv: int = DETAIL_SUBDIV if specs.size() <= 4 else OVERVIEW_SUBDIV
	var foam_texture: Texture2D = _foam_viewport.get_texture()
	for i: int in specs.size():
		var spec: Dictionary = specs[i] if specs[i] is Dictionary else {"id": specs[i]}
		var plot := WaterPlot.new()
		plot.name = "Plot%d" % i
		plot.position = _origin(i, specs.size())
		_plots_root.add_child(plot)
		plot.build(spec, PLOT_SIZE, subdiv, foam_texture, FOAM_LAYER)
		plot.set_label_size(0.011 if specs.size() <= 4 else 0.030)
		plots.append(plot)
		if (plot.entry["feeds"] as Array).has(WaterShaderRegistry.Feed.FOAM_MASK):
			_foam_plot = plot


## 지금 놓인 칸 전체가 화면에 들어오는 시점. 챕터는 yaw/pitch만 정한다.
##
## 눈대중 배수로는 안 맞는다. 내려다볼수록 가까운 줄이 카메라 쪽으로 튀어나와
## 실제 필요한 거리가 크게 달라지기 때문이다. 그래서 내용물의 모서리를 카메라
## 좌표로 옮겨 놓고, 전부 화면 안에 들어오는 최소 거리와 상하 중앙에 오는
## 높이를 번갈아 푼다.
func frame(yaw: float, pitch: float, margin := 1.06) -> void:
	# 칸 배치를 시점 쪽으로 통째로 돌린다. 그래야 나란히 놓은 두 칸이 언제나
	# 화면에 정면으로 서고, 앞뒤로 밀려 크기가 달라지지 않는다. 해는 월드에
	# 고정이므로 반사 경로를 화면에 넣으려면 이 각도를 쓰면 된다.
	_plots_root.rotation.y = yaw

	var count: int = plots.size()
	var columns: int = count if count <= 4 else int(ceil(sqrt(float(count))))
	var rows: int = int(ceil(float(count) / float(columns)))
	var half_w: float = float(columns - 1) * SPACING * 0.5 + PLOT_SIZE * 0.5
	var half_d: float = float(rows - 1) * SPACING * 0.5 + PLOT_SIZE * 0.5
	# 바닥 상자 아래쪽까지 넣으면 화면이 쓸데없이 멀어진다. 봐야 하는 건 수면
	# 언저리와 기둥, 그리고 이름표 윗변까지다.
	var top := 3.5
	for plot: WaterPlot in plots:
		top = maxf(top, plot.label_top())

	var points: Array[Vector3] = []
	for sx: float in [-half_w, half_w] as Array[float]:
		for sz: float in [-half_d, half_d] as Array[float]:
			for sy: float in [-3.0, top] as Array[float]:
				points.append(Vector3(sx, sy, sz))

	# Camera3D는 KEEP_HEIGHT라 수직 화각만 고정(75도)이고 수평은 종횡비를 탄다.
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var tan_v: float = tan(deg_to_rad(37.5))
	var tan_h: float = tan_v * maxf(view_size.x / maxf(view_size.y, 1.0), 0.5)
	var basis := Basis.from_euler(Vector3(clampf(pitch, -1.35, -0.06), 0.0, 0.0))

	var lift := 0.0
	var distance := 0.0
	for _iteration: int in 3:
		distance = _fit_distance(points, basis, lift, tan_h, tan_v) * margin
		lift = _centre_lift(points, basis, lift, distance)
	camera_rig.position = Vector3(0.0, lift, 0.0)
	camera_rig.set_view(yaw, pitch, distance)


## 카메라가 (0, lift, 0)에서 basis.z 방향으로 물러날 때, 모든 점이 화면 안에
## 들어오는 최소 거리. 화면 좌표는 x/(z*tan_h), y/(z*tan_v)이므로 각 점이
## 요구하는 거리를 직접 풀 수 있다.
func _fit_distance(points: Array[Vector3], basis: Basis, lift: float,
		tan_h: float, tan_v: float) -> float:
	var needed := 0.0
	for point: Vector3 in points:
		var p: Vector3 = point - Vector3(0.0, lift, 0.0)
		var wide: float = absf(p.dot(basis.x)) / tan_h
		var tall: float = absf(p.dot(basis.y)) / tan_v
		needed = maxf(needed, maxf(wide, tall) + p.dot(basis.z))
	return needed


## 내용물의 화면상 위아래 끝이 대칭이 되는 카메라 높이. lift를 올리면 모든
## 점의 화면 y가 내려가므로 단조 함수고, 이분법이 그대로 먹는다.
func _centre_lift(points: Array[Vector3], basis: Basis, lift: float,
		distance: float) -> float:
	var low := lift - 30.0
	var high := lift + 30.0
	for _iteration: int in 20:
		var middle: float = (low + high) * 0.5
		if _screen_bias(points, basis, middle, distance) > 0.0:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5


func _screen_bias(points: Array[Vector3], basis: Basis, lift: float,
		distance: float) -> float:
	var lowest := INF
	var highest := -INF
	for point: Vector3 in points:
		var p: Vector3 = point - Vector3(0.0, lift, 0.0)
		var depth: float = distance - p.dot(basis.z)
		if depth < 0.01:
			continue
		var screen_y: float = p.dot(basis.y) / depth
		lowest = minf(lowest, screen_y)
		highest = maxf(highest, screen_y)
	if lowest == INF:
		return 0.0
	return lowest + highest


func plot_material(slot: int) -> ShaderMaterial:
	return plots[slot].material


func set_param(slot: int, uniform_name: String, value: Variant) -> void:
	if slot < plots.size():
		plots[slot].material.set_shader_parameter(uniform_name, value)


func set_param_all(uniform_name: String, value: Variant) -> void:
	for plot: WaterPlot in plots:
		plot.material.set_shader_parameter(uniform_name, value)


## 18번 전용. 물이 아니라 기둥·바위의 material_overlay 슬롯에 들어간다.
func set_overlay(spec: Variant) -> void:
	var overlay: ShaderMaterial = null
	if spec != null:
		overlay = _simple_material(spec)
	for plot: WaterPlot in plots:
		plot.set_overlay(overlay)


## canvas_item 셰이더(19·20·21·25)를 전체 화면 ColorRect에 올린다.
func set_canvas(spec: Variant) -> void:
	_canvas_layer.visible = spec != null
	_canvas_rect.material = _simple_material(spec) if spec != null else null


## 24번 전용. 화면 전체 후처리라 3D 위에 겹친다.
func set_postfx(spec: Variant) -> void:
	_postfx_layer.visible = spec != null
	_postfx_rect.material = _simple_material(spec) if spec != null else null


## 23번 전용. 수면 아래에서 위를 올려다보는 시점으로 갈아탄다.
func set_dive(on: bool, slot := 0) -> void:
	if on and slot < plots.size():
		_dive_rig.position = plots[slot].global_position
	_dive_rig.set_active(on)
	if not on:
		_camera.current = true


func environment() -> Environment:
	return _environment


func sun() -> DirectionalLight3D:
	return _sun


## 챕터 5가 사이드 패널에 실제 마스크를 띄울 때 쓴다.
func foam_texture() -> Texture2D:
	return _foam_viewport.get_texture()


func elapsed() -> float:
	return _elapsed


# --- 배치 --------------------------------------------------------------------

## 넷까지는 한 줄이 제일 잘 읽힌다. 그 이상은 정사각에 가까운 격자로 접는다.
func _origin(slot: int, total: int) -> Vector3:
	if total <= 4:
		return Vector3((float(slot) - float(total - 1) * 0.5) * SPACING, 0.0, 0.0)
	var columns: int = int(ceil(sqrt(float(total))))
	var rows: int = int(ceil(float(total) / float(columns)))
	var column: int = slot % columns
	var row: int = slot / columns
	return Vector3(
			(float(column) - float(columns - 1) * 0.5) * SPACING,
			0.0,
			(float(row) - float(rows - 1) * 0.5) * SPACING)


static func _simple_material(spec: Variant) -> ShaderMaterial:
	var dict: Dictionary = spec if spec is Dictionary else {"id": spec}
	var entry: Dictionary = WaterShaderRegistry.by_id(int(dict["id"]))
	var mat := ShaderMaterial.new()
	mat.shader = load(dict.get("shader", WaterShaderRegistry.shader_path(entry))) as Shader
	for uniform_name: String in entry["textures"]:
		var tex: Texture2D = WaterTextures.get_texture(entry["textures"][uniform_name])
		if tex != null:
			mat.set_shader_parameter(uniform_name, tex)
	for uniform_name: String in entry["params"]:
		mat.set_shader_parameter(uniform_name, entry["params"][uniform_name])
	var overrides: Dictionary = dict.get("params", {})
	for uniform_name: String in overrides:
		mat.set_shader_parameter(uniform_name, overrides[uniform_name])
	return mat
