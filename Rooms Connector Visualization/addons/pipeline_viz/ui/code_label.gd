extends RichTextLabel
## 코드 칸. Glossary가 넣어 준 [hint] 문자열을 기본 툴팁이 회색 한 덩어리로
## 띄우면 시그니처와 설명이 섞여 읽힌다. 여기서 셋으로 갈라 위계를 준다.
##
##   smoothstep(edge0, edge1, x) -> float   ← 시그니처: 고정폭, 강조색
##   ─────────────────────────────────
##   x가 edge0 이하면 0, edge1 이상이면 1,   ← 첫 줄: 이게 무엇인지. 밝게.
##   그 사이는 S자 곡선으로 부드럽게 넘어간다. ← 나머지: 한 톤 죽여서.
##
## Glossary.hint()가 "시그니처\n\n설명" 으로 만들어 주므로 빈 줄에서 자른다.

const SIGNATURE_SIZE := 12
const BODY_SIZE := 13


func _make_custom_tooltip(for_text: String) -> Object:
	if for_text.is_empty():
		return null
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	var parts := for_text.split("\n\n", true, 1)
	var body := for_text
	if parts.size() == 2:
		box.add_child(_signature(parts[0]))
		box.add_child(HSeparator.new())
		body = parts[1]
	var lines := body.split("\n")
	box.add_child(_line(lines[0], AppTheme.TEXT_MAIN))
	if lines.size() > 1:
		box.add_child(_line("\n".join(lines.slice(1)), AppTheme.TEXT_DIM))
	return box


func _signature(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", AppTheme.mono_font())
	label.add_theme_font_size_override("font_size", SIGNATURE_SIZE)
	label.add_theme_color_override("font_color", AppTheme.ACCENT)
	return label


func _line(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", BODY_SIZE)
	label.add_theme_color_override("font_color", color)
	return label
