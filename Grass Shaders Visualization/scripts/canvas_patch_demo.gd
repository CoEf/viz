extends Node3D
## Wires shader 10 (a canvas_item shader) into the 3D gallery.
##
## The shader paints into a SubViewport; the ground quad wears that viewport as its albedo.
## Unshaded, because the shader already decides its own final colour and letting the sun
## multiply it again would make this patch darker than its nine neighbours for reasons that
## have nothing to do with the shader being compared.

@onready var _viewport: SubViewport = $SubViewport
@onready var _patch: ColorRect = $SubViewport/Patch
@onready var _ground: MeshInstance3D = $Ground


func _ready() -> void:
	# Anchor the procedural noise to this patch's own place in the world, so it reads as
	# ground rather than as a screen effect.
	_patch.world_anchor = Vector2(global_position.x, global_position.z)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_ground.material_override = material


func get_blade_count() -> int:
	return 0
