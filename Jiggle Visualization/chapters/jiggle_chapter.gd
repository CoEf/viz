@abstract
class_name JiggleChapter
extends ChapterBase
## Jiggle 시각화 전용 챕터 베이스.
## 이 프로젝트에는 전역 셰이더 파라미터가 없어 reset_globals 는 비어 있다.
## 대신 이 프로젝트의 챕터들이 공통으로 쓰는 패널 컨트롤 헬퍼를 더한다.
## 해부 대상 월드는 챕터마다 타입이 달라서(공 · 몸 · 머리카락 · 천 · 캐릭터)
## 각 챕터 스크립트가 자기 타입으로 선언한다.


func reset_globals() -> void:
	# 슬로우모션 토글이 만지는 전역 배속을 챕터 진입마다 원상 복구한다.
	# 이 프로젝트에서 씬 밖에 사는 상태는 이것 하나뿐이다.
	Engine.time_scale = 1.0


## 한 번 누르는 동작(임펄스 등).
func add_button(
		parent: Container,
		text: String,
		on_pressed: Callable,
		steps: Array[int] = []) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	bind_steps([button], steps)
	return button


## 서로 배타적인 선택지(적분 방식 · 충돌 응답 · 자극 종류).
func add_option(
		parent: Container,
		text: String,
		options: PackedStringArray,
		selected: int,
		on_selected: Callable,
		steps: Array[int] = []) -> OptionButton:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	var option := OptionButton.new()
	for entry in options:
		option.add_item(entry)
	option.select(selected)
	option.item_selected.connect(on_selected)
	parent.add_child(option)
	bind_steps([label, option], steps)
	return option


## 슬로우모션 토글. 원본 Jiggle 문서가 "적극적으로 쓸 것"이라 못 박은 관찰 장치다 —
## 실시간으로는 '출렁인다' 이상이 안 보이지만, 0.15배속에서는 파티클이 목표를
## 지나쳤다가 되돌아오는 과정이 한 동작씩 보인다. 배속은 reset_globals 가 되돌린다.
func add_slowmo(parent: Container, steps: Array[int] = []) -> CheckButton:
	return add_toggle(
		parent,
		"슬로우모션 (0.15×)",
		false,
		func(pressed: bool) -> void: Engine.time_scale = 0.15 if pressed else 1.0,
		steps
	)


## 변위-시간 그래프. 부족감쇠/임계감쇠 차이는 3D보다 여기서 훨씬 선명하다.
## 채우는 쪽은 챕터의 _process 에서 plot.push_frame(world.sample_plot()).
func add_plot(
		parent: Container,
		series: Array[Dictionary],
		steps: Array[int] = []) -> JigglePlot:
	var plot := JigglePlot.new()
	plot.custom_minimum_size = Vector2(0.0, 150.0)
	plot.configure(series)
	parent.add_child(plot)
	bind_steps([plot], steps)
	return plot
