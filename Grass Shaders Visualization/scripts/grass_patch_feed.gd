@tool
extends ColorRect
## Feeds shader 10 the two uniforms its author's game script supplies.
##
## `camera_world_pos` and `camera_zoom` are what make the procedural noise stay *anchored*
## instead of sliding with the view. Here the patch is painted into a SubViewport and
## mapped onto a ground quad, so the anchor is the quad's own world position: the pattern
## belongs to that piece of ground, exactly as it would belong to a fixed piece of a 2D
## level. Flip `follow_camera` on to see the uniform actually being driven - the noise then
## scrolls under the ground quad as you fly around, which is the effect the shader is for
## in a scrolling 2D game and clearly the wrong one for a 3D floor.

@export var follow_camera: bool = false
@export var world_anchor: Vector2 = Vector2.ZERO
## World units per screen pixel assumed by the shader's `camera_world_pos / screen_size`.
@export var pixels_per_unit: float = 48.0
@export var zoom: float = 1.0


func _process(_delta: float) -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	var anchor: Vector2 = world_anchor
	if follow_camera:
		var camera: Camera3D = get_viewport().get_camera_3d()
		if camera == null and Engine.get_main_loop() is SceneTree:
			var tree := Engine.get_main_loop() as SceneTree
			if tree.root != null:
				camera = tree.root.get_camera_3d()
		if camera != null:
			anchor = Vector2(camera.global_position.x, camera.global_position.z)
	shader_material.set_shader_parameter("camera_world_pos", anchor * pixels_per_unit)
	shader_material.set_shader_parameter("camera_zoom", zoom)
