@abstract
class_name PainterChapter
extends ChapterBase
## Drawable Painter 시각화 전용 챕터 베이스.
## 1) 해부 대상 씬을 자기 타입으로 선언 — 챕터들이 world.* 를 타입 검사받으며 쓴다.
## 2) 이 프로젝트는 전역 셰이더 파라미터가 없어 reset_globals는 비워 둔다.
## 3) 여러 챕터가 같이 쓰는 "캔버스 라이브 뷰" 패널 헬퍼를 제공한다.

@onready var world: PainterWorld = $PainterWorld


## 사이드 패널에 라이브 텍스처 뷰(제목 + 정사각 TextureRect)를 붙인다.
## DrawableTexture2D를 그대로 물리므로 블릿 결과가 실시간으로 비친다.
func add_texture_view(parent: Container, title: String, texture: Texture2D,
		steps: Array[int] = [], side := 190.0) -> TextureRect:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color(1.0, 1.0, 1.0, 0.7)
	parent.add_child(label)
	var center := CenterContainer.new()
	var view := TextureRect.new()
	view.texture = texture
	view.custom_minimum_size = Vector2(side, side)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	center.add_child(view)
	parent.add_child(center)
	bind_steps([label, center], steps)
	return view
