@abstract
class_name ChapterBase
extends Node3D
## 모든 챕터의 공통 계약. 스텝 목록(제목+본문)과 스텝별 씬 상태, 우측 패널
## 컨트롤을 제공한다.
##
## 해부 대상 씬은 여기서 다루지 않는다. 프로젝트마다 타입이 다르므로,
## ChapterBase를 상속한 프로젝트 전용 베이스가 `@onready var world: MyWorld`
## 처럼 자기 타입으로 선언할 것(그래야 정적 타입 검사가 살아 있다).
## apply_step은 이전/다음 어느 쪽에서 와도 같은 결과가 나오도록 스텝마다
## 상태를 처음부터 다 지정한다(누적 아님).
## 스텝 데이터 키: title, body(bbcode), chips([{icon, text}]), code, try.
## 슬라이더와 연동되는 코드 칸은 update_code()로 실시간 갱신한다.
##
## 패널 컨트롤은 챕터당 한 번만 짓지만(값이 스텝을 넘어 유지된다), 보이는 건
## 스텝별로 다르다. add_* 의 마지막 `steps` 인자에 그 컨트롤이 실제로 화면을
## 바꾸는 스텝만 적을 것. 비워 두면 챕터 전 스텝에서 보인다. 만지면 아무 일도
## 안 일어나는 컨트롤을 그 스텝에서 치우는 게 목적이다.

signal live_code_changed(code: String)

var current_step := 0

## {"nodes": Array[Control], "steps": Array[int]} 목록. steps가 비면 항상 보인다.
var _panel_entries: Array[Dictionary] = []

@abstract func get_chapter_title() -> String


@abstract func get_steps() -> Array[Dictionary]


func get_step_count() -> int:
	return get_steps().size()


## 챕터 전환 시 러너가 먼저 호출한다. 전역 셰이더 파라미터나 Autoload처럼
## 씬 밖에 사는 상태를 이 챕터의 시작값으로 되돌릴 것.
func reset_globals() -> void:
	pass


func apply_step(_index: int) -> void:
	pass


func build_panel(_parent: VBoxContainer) -> void:
	pass


## 러너 전용 진입점. 등록부를 비우고 패널을 새로 짓는다.
func rebuild_panel(parent: VBoxContainer) -> void:
	_panel_entries.clear()
	build_panel(parent)


## 러너 전용. 스텝이 바뀔 때마다 호출되어, 그 스텝에서 실제로 듣는 컨트롤만 남긴다.
func sync_panel(index: int) -> void:
	for entry in _panel_entries:
		var steps: Array = entry["steps"]
		var shown := steps.is_empty() or steps.has(index)
		for node: Control in entry["nodes"]:
			node.visible = shown


func update_code(code: String) -> void:
	live_code_changed.emit(code)


## add_* 로 만들지 않고 직접 붙인 컨트롤도 스텝에 묶는다.
## 한 덩어리로 보이고 사라져야 하는 노드들을 함께 넘길 것.
func bind_steps(nodes: Array[Control], steps: Array[int]) -> void:
	if steps.is_empty():
		return
	_panel_entries.append({"nodes": nodes, "steps": steps})


func add_slider(
		parent: Container,
		text: String,
		min_value: float,
		max_value: float,
		value: float,
		on_changed: Callable,
		steps: Array[int] = []) -> HSlider:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.01
	slider.value = value
	slider.value_changed.connect(on_changed)
	parent.add_child(slider)
	bind_steps([label, slider], steps)
	return slider


func add_toggle(
		parent: Container,
		text: String,
		pressed: bool,
		on_toggled: Callable,
		steps: Array[int] = []) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.button_pressed = pressed
	toggle.toggled.connect(on_toggled)
	parent.add_child(toggle)
	bind_steps([toggle], steps)
	return toggle


func add_caption(parent: Container, text: String, steps: Array[int] = []) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color(1.0, 1.0, 1.0, 0.65)
	parent.add_child(label)
	bind_steps([label], steps)
	return label
