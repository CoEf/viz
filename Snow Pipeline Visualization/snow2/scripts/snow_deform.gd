class_name SnowDeform
extends Node
## Owns the DrawableTexture2D (Godot 4.7) compression heightmap:
## white = untouched snow, black = fully pressed. Stamps alpha-blend a soft
## dark brush into the map; a periodic low-alpha white blit lets snowfall
## slowly refill the trails.

const MAP_SIZE := 1024

@export var ground_material: ShaderMaterial
@export var brush: Texture2D
@export var region_size := Vector2(40.0, 40.0)
@export var brush_world_size := 1.1
@export_range(0.05, 1.0) var stamp_strength := 0.45
@export var refill_interval := 0.4
@export_range(0.0, 0.2) var refill_alpha := 0.01

var _map: DrawableTexture2D
var _refill_source: ImageTexture
var _refill_timer := 0.0


func _ready() -> void:
	_map = DrawableTexture2D.new()
	_map.setup(MAP_SIZE, MAP_SIZE, DrawableTexture2D.DRAWABLE_FORMAT_RGBAH, Color.WHITE, false)
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	_refill_source = ImageTexture.create_from_image(image)
	ground_material.set_shader_parameter("deform_map", _map)


func _process(delta: float) -> void:
	_refill_timer += delta
	if _refill_timer >= refill_interval:
		_refill_timer = 0.0
		_map.blit_rect(
				Rect2i(0, 0, MAP_SIZE, MAP_SIZE),
				_refill_source,
				Color(1.0, 1.0, 1.0, refill_alpha))


func stamp(world_position: Vector3) -> void:
	var uv := Vector2(world_position.x, world_position.z) / region_size + Vector2(0.5, 0.5)
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return
	var size_px := maxi(2, int(brush_world_size / region_size.x * float(MAP_SIZE)))
	var center := Vector2i((uv * float(MAP_SIZE)).round())
	var rect := Rect2i(center - Vector2i(size_px / 2, size_px / 2), Vector2i(size_px, size_px))
	_map.blit_rect(rect, brush, Color(0.0, 0.0, 0.0, stamp_strength))


func get_map_texture() -> Texture2D:
	return _map
