class_name MstTerrain
extends Node3D
## 원본 플러그인의 `MarchingSquaresTerrain` 중 알고리즘이 실제로 읽는 값만 남긴 호스트.
##
## 원본은 에디터 플러그인·언두리도·외부 저장(MSTDataHandler)에 묶여 있어 그대로는
## 게임 실행 중에 돌지 않는다. 여기서는 셀 생성기와 색 헬퍼, 잔디 심기가 참조하는
## 프로퍼티만 그대로 같은 이름으로 들고 있는다. 그래야 그 세 파일을 한 글자도
## 고치지 않고 원본 그대로 가져다 쓸 수 있다.

const CHUNK_DIMENSIONS := Vector3i(21, 32, 21)

# --- 셀 생성기가 읽는 값 -------------------------------------------------------
var dimensions: Vector3i = CHUNK_DIMENSIONS
var cell_size := Vector2(2.0, 2.0)
## 0 = 부드럽게 섞기, 1 = 하드 사각, 2 = 하드 삼각
var blend_mode: int = 0

# --- 잔디 심기가 읽는 값 -------------------------------------------------------
var grass_subdivisions: int = 3
var grass_size := Vector2(1.0, 1.0)
var grass_mesh: QuadMesh
var terrain_material: ShaderMaterial

var tex2_has_grass := true
var tex3_has_grass := false
var tex4_has_grass := false
var tex5_has_grass := false
var tex6_has_grass := false

var texture_scale_1 := 1.0
var texture_scale_2 := 1.0
var texture_scale_3 := 1.0
var texture_scale_4 := 1.0
var texture_scale_5 := 1.0
var texture_scale_6 := 1.0

var chunks: Dictionary = {}
