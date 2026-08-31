extends Node

## Pure dirt-erasure API.
##
## Creates and owns the DrawableTexture2D that acts as the dirt mask
## (R=1 dirty, R=0 clean), attaches it to the model's ShaderMaterial,
## and exposes erase_at / erase_segment for the controller to call.
## Has no opinion about when to erase or what nozzle is selected.

const _INIT_SHADER := preload("res://painter/shaders/init_dirt.gdshader")
const _ERASE_3D_SHADER := preload("res://painter/shaders/erase_dirt_3d.gdshader")
const _INIT_COVERAGE_SHADER := preload("res://painter/shaders/init_coverage.gdshader")

var _texture_size: Vector2i
var _erase_material: ShaderMaterial
var _erase_3d_material: ShaderMaterial
var _dirt_mask: DrawableTexture2D
var _coverage_mask: DrawableTexture2D # R=1 where a triangle covers this texel, R=0 empty UV

# blit_rect_multi requires both source and extra-output arrays to be non-empty.
# These satisfy the constraint without affecting actual paint output.
var _dummy_source: ImageTexture # 1×1 white — bound as blit_source0 (unused in shader)
var _dummy_drawable: DrawableTexture2D # same-size second render target — COLOR1 not written by shader


## Creates the dirt mask, initialises it solid white (100% dirty), then
## wires it into [param target_model]'s ShaderMaterial.
## Returns false if the model isn't set up with a ShaderMaterial.
func setup(target_model: MeshInstance3D, texture_size: Vector2i, erase_material: ShaderMaterial) -> bool:
	_texture_size = texture_size
	_erase_material = erase_material

	var surface_mat := target_model.material_override as ShaderMaterial
	if surface_mat == null:
		push_error("PowerWash: target model needs a ShaderMaterial (dirt_surface shader) as material_override")
		return false

	# Read the initial dirt pattern BEFORE replacing the shader parameter.
	# Designer sets dirt_mask in the scene inspector to any Texture2D (e.g. a grime PNG).
	# DrawableTexture2D itself is skipped — it has no meaningful image to copy.
	var initial_tex := surface_mat.get_shader_parameter("dirt_mask") as Texture2D
	if initial_tex is DrawableTexture2D:
		initial_tex = null

	_dirt_mask = DrawableTexture2D.new()
	_dirt_mask.setup(
		texture_size.x, texture_size.y,
		DrawableTexture2D.DRAWABLE_FORMAT_RGBA8,
		Color(1.0, 1.0, 1.0, 1.0),
		false
	)

	# 1×1 white ImageTexture — satisfies "sources non-empty" in blit_rect_multi
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_dummy_source = ImageTexture.create_from_image(img)

	# Same-size secondary DrawableTexture2D — satisfies "extras non-empty" in blit_rect_multi
	_dummy_drawable = DrawableTexture2D.new()
	_dummy_drawable.setup(texture_size.x, texture_size.y, DrawableTexture2D.DRAWABLE_FORMAT_RGBA8, Color.TRANSPARENT, false)

	if initial_tex != null:
		var init_mat := ShaderMaterial.new()
		init_mat.shader = _INIT_SHADER
		init_mat.set_shader_parameter("texture_size", Vector2(texture_size))
		var full_rect := Rect2(Vector2.ZERO, Vector2(texture_size))
		_dirt_mask.blit_rect_multi(full_rect, [initial_tex], [_dummy_drawable], Color.WHITE, 0, init_mat)

	surface_mat.set_shader_parameter("dirt_mask", _dirt_mask)

	if _erase_material:
		_erase_material.set_shader_parameter("texture_size", Vector2(texture_size))

	# 3D-projected erase path (Blender-style). Owns its own material since the
	# triangle uniforms differ entirely from the 2D stamp shader.
	_erase_3d_material = ShaderMaterial.new()
	_erase_3d_material.shader = _ERASE_3D_SHADER
	_erase_3d_material.set_shader_parameter("texture_size", Vector2(texture_size))

	# Coverage mask: R=1 where any UV triangle exists, R=0 for empty UV space.
	# Built lazily via build_coverage(); starts all-black until then.
	_coverage_mask = DrawableTexture2D.new()
	_coverage_mask.setup(texture_size.x, texture_size.y,
		DrawableTexture2D.DRAWABLE_FORMAT_RGBA8, Color(0.0, 0.0, 0.0, 1.0), false)

	return true


## Blits a single spray stamp onto the dirt mask at [param uv].
func erase_at(uv: Vector2, spray_size: float, nozzle: NozzlePreset) -> void:
	if _dirt_mask == null or nozzle == null or _erase_material == null:
		return

	_sync_nozzle_params(nozzle)

	var ds := Vector2.ONE * spray_size
	var rect := Rect2(uv * Vector2(_texture_size) - ds * 0.5, ds)

	_dirt_mask.blit_rect_multi(rect, [_dummy_source], [_dummy_drawable], Color(1, 1, 1, 1), 0, _erase_material)


## Interpolates stamps from [param from_uv] to [param to_uv] so that
## dragging at any speed leaves a continuous spray trail.
func erase_segment(from_uv: Vector2, to_uv: Vector2, steps_per_uv_unit: int, spray_size: float, nozzle: NozzlePreset) -> void:
	var num_steps := int(max(1.0, (to_uv - from_uv).length() * steps_per_uv_unit))

	for i in range(num_steps):
		var t := (i + 1.0) / float(num_steps)
		erase_at(from_uv.lerp(to_uv, t), spray_size, nozzle)


## Erases dirt along the brush capsule [param world_a]..[param world_b] by
## blitting each affected triangle directly into its UV region — no UV-space
## interpolation, so UV seams are handled correctly by construction.
## [param local_a]/[param local_b] are the capsule endpoints already converted
## into model-local space; [param local_radius] is the brush radius in that
## same space. [param triangles] comes from
## [method SurfacePickerComponent.get_triangles_in_capsule].
func erase_at_3d(local_a: Vector3, local_b: Vector3, local_radius: float, triangles: Array[Dictionary], nozzle: NozzlePreset) -> void:
	if _dirt_mask == null or nozzle == null or _erase_3d_material == null:
		return
	if triangles.is_empty():
		return

	_erase_3d_material.set_shader_parameter("brush_a", local_a)
	_erase_3d_material.set_shader_parameter("brush_b", local_b)
	_erase_3d_material.set_shader_parameter("brush_radius", local_radius)
	_erase_3d_material.set_shader_parameter("pressure", nozzle.pressure)

	var tex_size := Vector2(_texture_size)

	for tri in triangles:
		var uvs: Array = tri.uvs
		var positions: Array = tri.positions

		# UV bounding rect of the triangle, converted to pixels.
		var uv_min := Vector2(
			minf(minf(uvs[0].x, uvs[1].x), uvs[2].x),
			minf(minf(uvs[0].y, uvs[1].y), uvs[2].y))
		var uv_max := Vector2(
			maxf(maxf(uvs[0].x, uvs[1].x), uvs[2].x),
			maxf(maxf(uvs[0].y, uvs[1].y), uvs[2].y))

		var px_size := (uv_max - uv_min) * tex_size
		if px_size.x < 1.0 and px_size.y < 1.0:
			continue # degenerate / sub-pixel UV triangle — nothing to paint

		# Pad by 1px so the shader's EDGE_EPS dilation isn't clipped by the rect.
		var rect := Rect2(uv_min * tex_size, px_size).grow(1.0)

		_erase_3d_material.set_shader_parameter("tri_uv0", uvs[0])
		_erase_3d_material.set_shader_parameter("tri_uv1", uvs[1])
		_erase_3d_material.set_shader_parameter("tri_uv2", uvs[2])
		_erase_3d_material.set_shader_parameter("tri_pos0", positions[0])
		_erase_3d_material.set_shader_parameter("tri_pos1", positions[1])
		_erase_3d_material.set_shader_parameter("tri_pos2", positions[2])

		_dirt_mask.blit_rect_multi(rect, [_dummy_source], [_dummy_drawable], Color(1, 1, 1, 1), 0, _erase_3d_material)


## Rasterises every triangle in [param triangles] into the coverage mask so
## ProgressComponent can ignore empty UV space when computing clean %.
## Call once after setup(), passing [method SurfacePickerComponent.get_all_triangles].
func build_coverage(triangles: Array[Dictionary]) -> void:
	if _coverage_mask == null:
		return

	var cov_mat := ShaderMaterial.new()
	cov_mat.shader = _INIT_COVERAGE_SHADER
	cov_mat.set_shader_parameter("texture_size", Vector2(_texture_size))

	var tex_size := Vector2(_texture_size)

	for tri in triangles:
		var uvs: Array = tri.uvs

		var uv_min := Vector2(
			minf(minf(uvs[0].x, uvs[1].x), uvs[2].x),
			minf(minf(uvs[0].y, uvs[1].y), uvs[2].y))
		var uv_max := Vector2(
			maxf(maxf(uvs[0].x, uvs[1].x), uvs[2].x),
			maxf(maxf(uvs[0].y, uvs[1].y), uvs[2].y))

		var px_size := (uv_max - uv_min) * tex_size
		if px_size.x < 1.0 and px_size.y < 1.0:
			continue

		var rect := Rect2(uv_min * tex_size, px_size).grow(1.0)

		cov_mat.set_shader_parameter("tri_uv0", uvs[0])
		cov_mat.set_shader_parameter("tri_uv1", uvs[1])
		cov_mat.set_shader_parameter("tri_uv2", uvs[2])

		_coverage_mask.blit_rect_multi(rect, [_dummy_source], [_dummy_drawable],
			Color.WHITE, 0, cov_mat)


func get_coverage_mask() -> DrawableTexture2D:
	return _coverage_mask


func get_dirt_mask() -> DrawableTexture2D:
	return _dirt_mask


func _sync_nozzle_params(nozzle: NozzlePreset) -> void:
	_erase_material.set_shader_parameter("pressure", nozzle.pressure)
	if nozzle.spray_pattern != null:
		_erase_material.set_shader_parameter("spray_pattern", nozzle.spray_pattern)
