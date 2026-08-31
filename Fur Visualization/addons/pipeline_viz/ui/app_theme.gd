class_name AppTheme
extends RefCounted
## 앱 전체 UI 테마 — 컨셉: 가독성 좋은, 동글동글, 모던, 모바일.
## 필(pill) 버튼, 원형 그래버 슬라이더, iOS풍 토글 스위치, 라운드 카드 패널.
## 폰트: res://assets/fonts의 ttf/otf가 있으면 최우선, 없으면 시스템에 설치된
## Pretendard 계열 → 맑은 고딕 순으로 찾는다.

const BG_WINDOW := Color("101318")
const BG_CARD := Color("1b1f27")
const BG_CODE := Color("13161d")
const BG_CONTROL := Color("262d38")
const BG_CONTROL_HOVER := Color("323a48")
const BG_CONTROL_PRESSED := Color("3e4757")
const BG_TRACK := Color("2a303c")
const ACCENT := Color("6cb0f5")
const TEXT_MAIN := Color("e8ebf2")
const TEXT_DIM := Color("9aa3b2")

const FONT_DIR := "res://assets/fonts"


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = _app_font()
	theme.default_font_size = 15
	# NanumSquareRoundR처럼 Regular만 있는 폰트라도 [b] 태그가 실제로 굵어지도록
	# FontVariation으로 합성 볼드를 만들어 둔다.
	var bold := emboldened(theme.default_font, 0.45)
	theme.set_font("bold_font", "RichTextLabel", bold)
	theme.set_font("bold_italics_font", "RichTextLabel", bold)
	_style_button(theme)
	_style_check_button(theme)
	_style_slider(theme)
	_style_scrollbar(theme)
	theme.set_color("font_color", "Label", TEXT_MAIN)
	theme.set_color("default_color", "RichTextLabel", Color("dde2eb"))
	var separator := StyleBoxLine.new()
	separator.color = Color(1.0, 1.0, 1.0, 0.08)
	separator.thickness = 1
	theme.set_stylebox("separator", "HSeparator", separator)
	_style_tooltip(theme)
	return theme


## 코드 칸 용어 힌트가 뜨는 기본 툴팁. 손대지 않으면 OS 회색 상자로 떠서
## 앱 안에서 저 혼자 튄다. 여기 칠해 두면 다른 카드와 같은 얼굴이 된다.
static func _style_tooltip(theme: Theme) -> void:
	var panel := card_style(10)
	# 카드 색(BG_CARD)이나 컨트롤 색(BG_CONTROL)을 깔면 글자와의 밝기차가
	# 사이드 패널 본문보다 크게 묽어져 글자가 흐려 보인다. 코드 칸과 같은
	# 어두운 바탕을 깔아 대비를 벌어 준다 — 어차피 코드에 붙는 설명이다.
	panel.bg_color = BG_CODE
	panel.set_border_width_all(1)
	panel.border_color = Color(1.0, 1.0, 1.0, 0.10)
	panel.content_margin_left = 12.0
	panel.content_margin_right = 12.0
	panel.content_margin_top = 9.0
	panel.content_margin_bottom = 9.0
	theme.set_stylebox("panel", "TooltipPanel", panel)
	theme.set_color("font_color", "TooltipLabel", TEXT_MAIN)
	theme.set_font_size("font_size", "TooltipLabel", 13)


## 코드 칸에 쓰는 고정폭 폰트. 툴팁 시그니처도 같은 얼굴을 써야 코드에서
## 집어 온 문장이라는 게 읽힌다. 매번 만들지 않도록 한 벌만 들고 있는다.
static var _mono_font: SystemFont


static func mono_font() -> SystemFont:
	if _mono_font == null:
		_mono_font = SystemFont.new()
		_mono_font.font_names = PackedStringArray(
				["Cascadia Mono", "Consolas", "Courier New"])
		# 웹 빌드에는 설치된 시스템 폰트가 하나도 없다. 위 이름이 전부
		# 빗나가면 코드 칸의 한글 주석이 두부가 되므로, 번들 폰트를
		# 뒤에 세워 글리프만이라도 이어받게 한다.
		var fallback_list: Array[Font] = [_app_font()]
		_mono_font.fallbacks = fallback_list
	return _mono_font


static func emboldened(font: Font, amount: float) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = font
	variation.variation_embolden = amount
	return variation


static func card_style(radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_CARD
	style.set_corner_radius_all(radius)
	return style


static func code_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_CODE
	style.set_corner_radius_all(10)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style


static func _app_font() -> Font:
	var system := SystemFont.new()
	system.font_names = PackedStringArray([
		"Pretendard Variable", "Pretendard", "SUIT Variable", "SUIT",
		"NanumSquareRound", "Noto Sans KR", "Malgun Gothic",
	])
	var custom := _load_custom_font()
	if custom != null:
		var fallback_list: Array[Font] = [system]
		custom.fallbacks = fallback_list
		return custom
	return system


static func _load_custom_font() -> FontFile:
	if not DirAccess.dir_exists_absolute(FONT_DIR):
		return null
	for file in DirAccess.get_files_at(FONT_DIR):
		# 내보낸 빌드에 원본 ttf는 들어가지 않는다. 폴더에는 .ttf.import 만
		# 남고 실체는 .godot/imported 의 fontdata다. 그래서 껍데기를 벗겨
		# 원래 경로로 load() 한다 — 파일 바이트를 직접 읽는
		# load_dynamic_font()는 빌드에서 반드시 실패한다.
		var path := FONT_DIR.path_join(file.trim_suffix(".import"))
		var ext := path.get_extension().to_lower()
		if ext != "ttf" and ext != "otf":
			continue
		var font := ResourceLoader.load(path) as FontFile
		if font != null:
			return font
	return null


static func _pill(bg: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(18)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style


static func _style_button(theme: Theme) -> void:
	theme.set_stylebox("normal", "Button", _pill(BG_CONTROL))
	theme.set_stylebox("hover", "Button", _pill(BG_CONTROL_HOVER))
	theme.set_stylebox("pressed", "Button", _pill(BG_CONTROL_PRESSED))
	theme.set_stylebox("disabled", "Button",
			_pill(Color(BG_CONTROL.r, BG_CONTROL.g, BG_CONTROL.b, 0.45)))
	var focus := _pill(Color(0.0, 0.0, 0.0, 0.0))
	focus.draw_center = false
	focus.set_border_width_all(2)
	focus.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.55)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_color("font_color", "Button", TEXT_MAIN)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color.WHITE)
	theme.set_color("font_focus_color", "Button", TEXT_MAIN)
	theme.set_color("font_disabled_color", "Button",
			Color(TEXT_DIM.r, TEXT_DIM.g, TEXT_DIM.b, 0.55))


static func _style_check_button(theme: Theme) -> void:
	# CheckButton은 클래스 체인 때문에 Button의 필 배경을 물려받으므로 비워 준다.
	var empty := StyleBoxEmpty.new()
	empty.content_margin_top = 4.0
	empty.content_margin_bottom = 4.0
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "CheckButton", empty)
	theme.set_icon("checked", "CheckButton", _switch_texture(true))
	theme.set_icon("unchecked", "CheckButton", _switch_texture(false))
	theme.set_icon("checked_disabled", "CheckButton", _switch_texture(true))
	theme.set_icon("unchecked_disabled", "CheckButton", _switch_texture(false))
	theme.set_color("font_color", "CheckButton", TEXT_MAIN)
	theme.set_color("font_hover_color", "CheckButton", Color.WHITE)
	theme.set_color("font_pressed_color", "CheckButton", TEXT_MAIN)


static func _style_slider(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = BG_TRACK
	track.set_corner_radius_all(3)
	track.content_margin_top = 3.0
	track.content_margin_bottom = 3.0
	theme.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(3)
	theme.set_stylebox("grabber_area", "HSlider", fill)
	var fill_highlight := StyleBoxFlat.new()
	fill_highlight.bg_color = ACCENT.lightened(0.15)
	fill_highlight.set_corner_radius_all(3)
	theme.set_stylebox("grabber_area_highlight", "HSlider", fill_highlight)
	theme.set_icon("grabber", "HSlider", _circle_texture(18, Color("eef2f8")))
	theme.set_icon("grabber_highlight", "HSlider", _circle_texture(20, Color.WHITE))
	theme.set_icon("grabber_disabled", "HSlider", _circle_texture(18, Color("6a7280")))


static func _style_scrollbar(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1.0, 1.0, 1.0, 0.03)
	track.set_corner_radius_all(4)
	track.content_margin_left = 2.0
	track.content_margin_right = 2.0
	theme.set_stylebox("scroll", "VScrollBar", track)
	for entry in [["grabber", 0.14], ["grabber_highlight", 0.22], ["grabber_pressed", 0.3]]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = Color(1.0, 1.0, 1.0, entry[1] as float)
		grabber.set_corner_radius_all(4)
		theme.set_stylebox(entry[0] as String, "VScrollBar", grabber)


static func _circle_texture(diameter: int, color: Color) -> ImageTexture:
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	var center := diameter / 2.0
	for y in diameter:
		for x in diameter:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(center, center))
			var alpha := clampf(center - dist, 0.0, 1.0)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))
	return ImageTexture.create_from_image(image)


static func _switch_texture(active: bool) -> ImageTexture:
	const WIDTH := 44
	const HEIGHT := 26
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	var track_color := ACCENT if active else Color("3a4150")
	var half := HEIGHT / 2.0
	var radius := half - 1.0
	var knob_x := WIDTH - half - 1.0 if active else half + 1.0
	for y in HEIGHT:
		for x in WIDTH:
			var point := Vector2(x + 0.5, y + 0.5)
			# 트랙은 캡슐(양 끝 반원) SDF, 노브는 원 SDF로 안티앨리어싱해 그린다.
			var center_x := clampf(point.x, half, WIDTH - half)
			var track_dist := point.distance_to(Vector2(center_x, half)) - radius
			var track_alpha := clampf(0.5 - track_dist, 0.0, 1.0)
			var color := Color(track_color.r, track_color.g, track_color.b, track_alpha)
			var knob_dist := point.distance_to(Vector2(knob_x, half)) - (radius - 3.0)
			var knob_alpha := clampf(0.5 - knob_dist, 0.0, 1.0)
			if knob_alpha > 0.0:
				color = color.lerp(Color(0.96, 0.97, 1.0), knob_alpha)
				color.a = maxf(track_alpha, knob_alpha)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)
