extends Node

## Pure painting API.
##
## Owns the three DrawableTexture2D outputs (albedo/normal/orm) and the
## shared draw ShaderMaterial. Knows how to blit a brush stamp at a UV
## coordinate, or interpolate a stroke between two UV coordinates.
## Has no opinion about *when* to paint, what brush is selected, or where
## input comes from - that's the controller's job.

var _texture_size: Vector2i = Vector2i.ZERO
var _material: ShaderMaterial

var _albedo_texture: DrawableTexture2D
var _normal_texture: DrawableTexture2D
var _orm_texture: DrawableTexture2D


## Reads the ORMMaterial3D drawable textures off [param plushy], allocates
## them at [param texture_size] and remembers [param material] for later
## paint() calls. Returns false (and logs an error) if the mesh isn't set
## up with drawable textures.
func setup(plushy: MeshInstance3D, texture_size: Vector2i, material: ShaderMaterial) -> bool:
	_texture_size = texture_size
	_material = material

	var orm_material: ORMMaterial3D = plushy.material_override as ORMMaterial3D

	if orm_material == null:
		push_error("The plushy needs an OrmMaterial3D in material override with drawable textures for each in albedo, normal and orm")
		return false

	_albedo_texture = orm_material.albedo_texture as DrawableTexture2D
	_normal_texture = orm_material.normal_texture as DrawableTexture2D
	_orm_texture = orm_material.orm_texture as DrawableTexture2D

	if _albedo_texture == null or _normal_texture == null or _orm_texture == null:
		push_error("The plushy needs an OrmMaterial3D in material override with drawable textures for each in albedo, normal and orm")
		return false

	_albedo_texture.setup(
		texture_size.x, texture_size.y,
		DrawableTexture2D.DRAWABLE_FORMAT_RGBA8_SRGB,
		Color(0.75, 0.75, 0.75, 1.0),
		false
	)

	_normal_texture.setup(
		texture_size.x, texture_size.y,
		DrawableTexture2D.DRAWABLE_FORMAT_RGBA8,
		Color(0.5, 0.5, 1.0, 1.0),
		false
	)

	_orm_texture.setup(
		texture_size.x, texture_size.y,
		DrawableTexture2D.DRAWABLE_FORMAT_RGBA8,
		Color(0.0, 1.0, 0.0, 1.0),
		false
	)

	if _material:
		_material.set_shader_parameter("texture_size", texture_size)

	return true


## Stamps [param brush] once at [param uv], sized [param draw_size] pixels.
func paint_at(uv: Vector2, draw_size: float, brush: BrushSet) -> void:
	if _albedo_texture == null or brush == null or _material == null:
		return

	var ds: Vector2 = Vector2.ONE * draw_size
	var rect := Rect2(uv * Vector2(_texture_size) - ds * 0.5, ds)

	_albedo_texture.blit_rect_multi(
		rect,
		[brush.albedo_texture, brush.normal_texture],
		[_normal_texture, _orm_texture],
		Color(1.0, 1.0, 1.0, 1.0),
		0,
		_material
	)


## Stamps along the line from [param from_uv] to [param to_uv], spaced by
## [param steps_per_uv_unit] steps per UV unit of travel - used for
## continuous-drag drawing so strokes don't gap out between frames.
func paint_segment(from_uv: Vector2, to_uv: Vector2, steps_per_uv_unit: int, draw_size: float, brush: BrushSet) -> void:
	var num_steps: int = int(max(1.0, (to_uv - from_uv).length() * steps_per_uv_unit))

	for i in range(num_steps):
		var t: float = (i + 1.0) / float(num_steps)
		var uv: Vector2 = from_uv.lerp(to_uv, t)

		paint_at(uv, draw_size, brush)


func get_albedo_texture() -> DrawableTexture2D:
	return _albedo_texture


func get_normal_texture() -> DrawableTexture2D:
	return _normal_texture


func get_orm_texture() -> DrawableTexture2D:
	return _orm_texture
