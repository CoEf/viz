@tool
extends MeshInstance3D
## 이식본: effects/fur/scripts/fur_builder.gd
## 원본과의 차이: _ready 본문을 rebuild()로 뽑아 챕터가
## resolution 슬라이더로 다시 구울 수 있게 했다. 로직은 동일.

@export var target_mesh_instance : MeshInstance3D
@export var resolution : int = 10

func _ready():
	rebuild()

func rebuild():
	var source_mesh = target_mesh_instance.mesh
	var final_mesh : ArrayMesh = ArrayMesh.new()
	
	for i in resolution:
		var percent : float = ((i + 1) / float(resolution))
		var mt = MeshDataTool.new()
		mt.create_from_surface(source_mesh, 0)
		for v_idx in mt.get_vertex_count():
			var base_color = mt.get_vertex_color(v_idx)
			mt.set_vertex_color(v_idx, Color(percent * 0.5, base_color.g, 0.0))
		mt.commit_to_surface(final_mesh)
	mesh = final_mesh
	skin = target_mesh_instance.skin
