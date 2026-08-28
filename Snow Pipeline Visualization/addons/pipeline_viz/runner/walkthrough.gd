extends Control
## 워크스루 관리자: 챕터 로드, 스텝 진행, 스텝 카드(본문·재료 칩·코드·확인 유도)
## 렌더링을 담당한다. `-- --autotour [폴더]` 사용자 인자로 실행하면 모든
## 챕터·스텝을 자동으로 돌며 스크린샷을 남기고 종료한다.


## 챕터는 이 폴더에서 파일명 순으로 읽는다. chapter_0_*.tscn, chapter_1_*.tscn …
@export_dir var chapters_dir := "res://chapters"

const CHIP_ICONS := {
	"node3d": preload("res://addons/pipeline_viz/ui/icons/node3d.svg"),
	"resource": preload("res://addons/pipeline_viz/ui/icons/resource.svg"),
	"shader": preload("res://addons/pipeline_viz/ui/icons/shader.svg"),
	"texture": preload("res://addons/pipeline_viz/ui/icons/texture.svg"),
	"signal": preload("res://addons/pipeline_viz/ui/icons/signal.svg"),
	"script": preload("res://addons/pipeline_viz/ui/icons/script.svg"),
	"setting": preload("res://addons/pipeline_viz/ui/icons/setting.svg"),
}

var _chapter_scenes: Array[PackedScene] = []
var _chapter: ChapterBase
var _chapter_index := 0
var _step_index := 0

@onready var _viewport: SubViewport = %World
@onready var _side_panel: PanelContainer = %SidePanel
@onready var _bottom_bar: PanelContainer = %BottomBar
@onready var _chapter_title: Label = %ChapterTitle
@onready var _step_title: Label = %StepTitle
@onready var _step_body: RichTextLabel = %StepBody
@onready var _step_indicator: Label = %StepIndicator
@onready var _prev_step_button: Button = %PrevStepButton
@onready var _next_step_button: Button = %NextStepButton
@onready var _chips_row: HFlowContainer = %ChipsRow
@onready var _code_panel: PanelContainer = %CodePanel
@onready var _code_label: RichTextLabel = %CodeLabel
@onready var _try_line: Label = %TryLine
@onready var _panel_divider: HSeparator = %PanelDivider
@onready var _panel_hint: Label = %PanelHint
@onready var _chapter_panel: VBoxContainer = %ChapterPanel
@onready var _chapter_indicator: Label = %ChapterIndicator
@onready var _prev_chapter_button: Button = %PrevChapterButton
@onready var _next_chapter_button: Button = %NextChapterButton


func _ready() -> void:
	_chapter_scenes = _scan_chapters()
	if _chapter_scenes.is_empty():
		push_error("pipeline_viz: %s 에 chapter_*.tscn 이 없습니다" % chapters_dir)
		return
	theme = AppTheme.build()
	# 툴팁 팝업은 이 Control이 아니라 창에 붙어서 뜬다. 창에도 같은 테마를
	# 걸어 두지 않으면 코드 용어 힌트만 기본 회색 상자로 뜬다.
	get_window().theme = theme
	RenderingServer.set_default_clear_color(AppTheme.BG_WINDOW)
	_style_step_card()
	_prev_step_button.pressed.connect(_on_prev_step_pressed)
	_next_step_button.pressed.connect(_on_next_step_pressed)
	_prev_chapter_button.pressed.connect(_on_prev_chapter_pressed)
	_next_chapter_button.pressed.connect(_on_next_chapter_pressed)
	_load_chapter(0)
	var args := OS.get_cmdline_user_args()
	var tour_index := args.find("--autotour")
	if tour_index != -1:
		var directory := "user://tour"
		if tour_index + 1 < args.size():
			directory = args[tour_index + 1]
		_run_tour.call_deferred(directory)


func _style_step_card() -> void:
	_side_panel.add_theme_stylebox_override("panel", AppTheme.card_style(16))
	_bottom_bar.add_theme_stylebox_override("panel", AppTheme.card_style(18))
	_code_panel.add_theme_stylebox_override("panel", AppTheme.code_style())
	# 챕터명은 맥락(작은 키커), 스텝 제목이 주인공이 되도록 위계를 뒤집는다.
	_chapter_title.add_theme_font_size_override("font_size", 15)
	_chapter_title.add_theme_color_override("font_color", AppTheme.TEXT_DIM)
	_step_title.add_theme_font_override("font", AppTheme.emboldened(theme.default_font, 0.5))
	_step_title.add_theme_font_size_override("font_size", 23)
	_step_title.add_theme_color_override("font_color", Color.WHITE)
	_code_label.add_theme_font_override("normal_font", AppTheme.mono_font())
	_code_label.add_theme_font_size_override("normal_font_size", 13)
	_try_line.modulate = Color(0.72, 0.87, 1.0)
	_panel_hint.add_theme_color_override("font_color", AppTheme.TEXT_DIM)


## 파일명 정렬이 곧 챕터 순서다. chapter_10_* 이 chapter_2_* 보다 앞서지 않도록
## 자릿수를 맞춰 이름 짓거나, 10개를 넘기지 말 것.
func _scan_chapters() -> Array[PackedScene]:
	var scenes: Array[PackedScene] = []
	var names := DirAccess.get_files_at(chapters_dir)
	names.sort()
	for name in names:
		# 내보낸 빌드에서는 .tscn 이 .scn 으로 구워지고, 폴더에는 원래 경로를
		# 가리키는 .tscn.remap 만 남는다. 껍데기를 벗겨야 에디터에서와 같은
		# 이름으로 걸린다 — 안 벗기면 익스포트한 빌드에서만 챕터가 0개가 된다.
		var res_name := name.trim_suffix(".remap")
		if not res_name.begins_with("chapter_") or not res_name.ends_with(".tscn"):
			continue
		var scene := load(chapters_dir.path_join(res_name)) as PackedScene
		if scene != null:
			scenes.append(scene)
	return scenes


func _load_chapter(index: int) -> void:
	_chapter_index = clampi(index, 0, _chapter_scenes.size() - 1)
	if _chapter != null:
		_chapter.free()
	_chapter = _chapter_scenes[_chapter_index].instantiate() as ChapterBase
	# _ready보다 먼저 부른다 — 챕터가 자기 시작값으로 덮어쓸 수 있어야 하므로.
	_chapter.reset_globals()
	_chapter.live_code_changed.connect(_on_live_code_changed)
	_viewport.add_child(_chapter)
	# queue_free만으로는 이번 프레임 끝까지 자식으로 남아, 바로 뒤 패널 동기화가
	# 지난 챕터 컨트롤을 세어 버린다. 트리에서 먼저 떼어 낸다.
	for child in _chapter_panel.get_children():
		_chapter_panel.remove_child(child)
		child.queue_free()
	_chapter.rebuild_panel(_chapter_panel)
	_chapter_title.text = "챕터 %d — %s" % [_chapter_index, _chapter.get_chapter_title()]
	_chapter_indicator.text = "챕터 %d / %d" % [_chapter_index, _chapter_scenes.size() - 1]
	_prev_chapter_button.disabled = _chapter_index == 0
	_next_chapter_button.disabled = _chapter_index == _chapter_scenes.size() - 1
	_set_step(0)


func _set_step(index: int) -> void:
	var steps := _chapter.get_steps()
	_step_index = clampi(index, 0, steps.size() - 1)
	var step: Dictionary = steps[_step_index]
	_step_title.text = str(step["title"])
	_step_body.text = str(step["body"])
	_render_chips(step.get("chips", []) as Array)
	var code := str(step.get("code", ""))
	_code_panel.visible = not code.is_empty()
	if not code.is_empty():
		_code_label.text = CodeFormat.format(code)
	var try_text := str(step.get("try", ""))
	_try_line.visible = not try_text.is_empty()
	_try_line.text = "▸ " + try_text
	_step_indicator.text = "%d / %d" % [_step_index + 1, steps.size()]
	_prev_step_button.disabled = _step_index == 0
	_next_step_button.disabled = _step_index == steps.size() - 1
	_chapter.current_step = _step_index
	_chapter.apply_step(_step_index)
	_sync_chapter_panel()


## 컨트롤은 챕터당 한 번만 짓고, 스텝마다 그 스텝에서 듣는 것만 남긴다.
## 남는 게 하나도 없으면 칸막이와 안내문까지 통째로 감춘다.
func _sync_chapter_panel() -> void:
	_chapter.sync_panel(_step_index)
	var has_control := false
	for child in _chapter_panel.get_children():
		var control := child as Control
		if control != null and control.visible:
			has_control = true
			break
	_chapter_panel.visible = has_control
	_panel_divider.visible = has_control
	_panel_hint.visible = has_control


func _render_chips(chips: Array) -> void:
	for child in _chips_row.get_children():
		child.queue_free()
	_chips_row.visible = not chips.is_empty()
	for i in chips.size():
		if i > 0:
			var arrow := Label.new()
			arrow.text = "→"
			arrow.modulate = Color(1.0, 1.0, 1.0, 0.4)
			_chips_row.add_child(arrow)
		var chip: Dictionary = chips[i]
		_chips_row.add_child(_make_chip(str(chip.get("icon", "setting")), str(chip.get("text", ""))))


func _make_chip(icon_name: String, text: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.07)
	style.set_corner_radius_all(10)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var icon := TextureRect.new()
	icon.texture = CHIP_ICONS.get(icon_name, CHIP_ICONS["setting"])
	icon.custom_minimum_size = Vector2(16.0, 16.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	row.add_child(icon)
	row.add_child(label)
	panel.add_child(row)
	return panel


func _on_live_code_changed(code: String) -> void:
	_code_panel.visible = not code.is_empty()
	_code_label.text = CodeFormat.format(code)


func _on_prev_step_pressed() -> void:
	_set_step(_step_index - 1)


func _on_next_step_pressed() -> void:
	_set_step(_step_index + 1)


func _on_prev_chapter_pressed() -> void:
	_load_chapter(_chapter_index - 1)


func _on_next_chapter_pressed() -> void:
	_load_chapter(_chapter_index + 1)


func _run_tour(directory: String) -> void:
	var absolute := ProjectSettings.globalize_path(directory)
	DirAccess.make_dir_recursive_absolute(absolute)
	for chapter_index in _chapter_scenes.size():
		_load_chapter(chapter_index)
		for step_index in _chapter.get_step_count():
			_set_step(step_index)
			for _frame in 10:
				await RenderingServer.frame_post_draw
			var image: Image = get_viewport().get_texture().get_image()
			image.save_png(absolute.path_join(
					"chapter_%d_step_%d.png" % [chapter_index, step_index]))
	print("autotour: captured all chapters to ", absolute)
	get_tree().quit()
