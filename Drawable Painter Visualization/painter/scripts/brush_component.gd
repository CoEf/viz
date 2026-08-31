extends Node

## Owns the active brush/mask selection and paint configuration (size,
## opacity, mask scale), and keeps the shared draw ShaderMaterial in sync
## with it. Only exposes actions like next/previous/set - it never reads
## input or scene-tree state itself, and never decides *when* to act.

signal brush_changed(index: int)
signal mask_changed(index: int)
signal size_changed(px: float)
signal opacity_changed(v: float)
signal mask_scale_changed(v: float)

var brushes: Array[BrushSet] = []
var masks: Array[BrushMask] = []

var draw_size_min: float = 16.0
var draw_size_max: float = 128.0
var mask_scale_max: float = 3.0

var draw_size: float = 32.0
var opacity: float = 0.0
var mask_scale: float = 1.0

var _material: ShaderMaterial
var _selected_brush: int = 0
var _selected_mask: int = 0


func setup(material: ShaderMaterial, brush_list: Array[BrushSet], mask_list: Array[BrushMask],
		size_min: float, size_max: float, max_mask_scale: float) -> void:
	_material = material
	brushes = brush_list
	masks = mask_list
	draw_size_min = size_min
	draw_size_max = size_max
	mask_scale_max = max_mask_scale


func set_brush(index: int) -> void:
	if brushes.is_empty():
		return

	_selected_brush = clamp(index, 0, brushes.size() - 1)
	var brush: BrushSet = brushes[_selected_brush]

	_material.set_shader_parameter("ao_texture", brush.occlusion_texture)
	_material.set_shader_parameter("roughness_texture", brush.roughness_texture)
	_material.set_shader_parameter("metallic_texture", brush.metallic_texture)

	brush_changed.emit(_selected_brush)


func next_brush() -> void:
	if brushes.is_empty():
		return

	set_brush((_selected_brush + 1) % brushes.size())


func previous_brush() -> void:
	if brushes.is_empty():
		return

	set_brush((_selected_brush + (brushes.size() - 1)) % brushes.size())


func set_mask(index: int) -> void:
	if masks.is_empty():
		return

	_selected_mask = clamp(index, 0, masks.size() - 1)
	var mask: BrushMask = masks[_selected_mask]

	_material.set_shader_parameter("mask", mask.mask_texture)
	_material.set_shader_parameter("blendMaskWithCirlce", mask.blend_mask_with_circle)

	mask_changed.emit(_selected_mask)


func next_mask() -> void:
	if masks.is_empty():
		return

	set_mask((_selected_mask + 1) % masks.size())


func previous_mask() -> void:
	if masks.is_empty():
		return

	set_mask((_selected_mask + (masks.size() - 1)) % masks.size())


func set_size(px: float) -> void:
	draw_size = clamp(px, draw_size_min, draw_size_max)
	size_changed.emit(draw_size)


func grow_size(factor: float) -> void:
	set_size(draw_size * (1.0 + factor))


func shrink_size(factor: float) -> void:
	set_size(draw_size / (1.0 + factor))


func set_opacity(v: float) -> void:
	opacity = clamp(v, 0.0, 1.0)
	_material.set_shader_parameter("opacity", opacity)
	opacity_changed.emit(opacity)


func set_mask_scale(v: float) -> void:
	mask_scale = clamp(v, 1.0 / mask_scale_max, mask_scale_max)
	_material.set_shader_parameter("maskScale", 1.0 / mask_scale)
	mask_scale_changed.emit(mask_scale)


func set_mask_scale_normalized(v: float) -> void:
	set_mask_scale(mask_scale_from_normalized(v))


func mask_scale_from_normalized(normalized: float) -> float:
	var value: float = lerp(-1.0, 1.0, normalized)
	return pow(mask_scale_max, value)


func mask_scale_to_normalized(scale: float) -> float:
	var exp_value: float = log(scale) / log(mask_scale_max)
	return (exp_value + 1.0) / 2.0


## Randomizes the mask's rotation/offset shader params - called once per
## new stroke (mouse down) so repeated stamps with the same mask don't
## look identically tiled.
func randomize_mask_transform() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	_material.set_shader_parameter("maskRotation", lerp(0.0, TAU, rng.randf()))
	_material.set_shader_parameter("maskOffset", Vector2(rng.randf(), rng.randf()))


func get_current_brush() -> BrushSet:
	if brushes.is_empty():
		return null

	return brushes[_selected_brush]


func get_current_mask() -> BrushMask:
	if masks.is_empty():
		return null

	return masks[_selected_mask]


func get_selected_brush_index() -> int:
	return _selected_brush


func get_selected_mask_index() -> int:
	return _selected_mask
