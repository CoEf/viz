class_name CodeFormat
extends RefCounted
## 코드 문자열을 RichTextLabel용 bbcode로 하이라이트한다.
## 토큰 단위로 한 번만 치환하므로 삽입된 색 태그를 다시 무는 일이 없다.
##
## Glossary에 있는 단어는 여기서 [hint]로 감싼다. 그래서 챕터는 아무것도 안 해도
## 코드 칸에 설명이 붙는다 — 사전을 늘리는 것만으로 다섯 프로젝트가 같이 늘어난다.
## 색은 사전 등재 여부가 아니라 그 단어의 문법 역할(Glossary.kind_of)에서 나온다.

const COLOR_TEXT := "#d8dee9"
const COLOR_KEYWORD := "#c792ea"
const COLOR_TYPE := "#7fd1c8"
const COLOR_NUMBER := "#e8c07a"
const COLOR_STRING := "#a8d18f"
const COLOR_COMMENT := "#7b8496"
# 부를 수 있는 것 — GLSL 내장 함수, Godot 메서드, 셰이더 진입점.
const COLOR_FUNCTION := "#82aaff"

## 사전에 등재된 단어의 색은 그 단어가 문법적으로 무엇이냐로 정한다.
## "사전에 있음"을 색으로 알리지는 않는다 — 코드에 뜨는 엔진 이름이 거의 다
## 사전에 있는 지금, 그건 아무것도 구별해 주지 못한다.
## 프로퍼티는 일부러 색이 없다. 원래 문법에서도 그냥 식별자이고, 설명은
## 마우스를 올리면 나온다.
const KIND_COLORS := {
	"function": COLOR_FUNCTION,
	"type": COLOR_TYPE,
	"keyword": COLOR_KEYWORD,
	"property": "",
}

const KEYWORDS := [
	"func", "var", "const", "signal", "extends", "return", "if", "else", "elif",
	"for", "in", "and", "or", "not", "true", "false", "void", "uniform", "varying",
	"float", "int", "bool", "vec2", "vec3", "vec4", "mat3", "mat4", "shader_type",
]

## 이 뒤에 바로 붙어 나오는 #은 주석이 아니라 셰이더 전처리기다.
const PREPROCESSOR := [
	"define", "undef", "ifdef", "ifndef", "if", "else", "elif", "endif",
	"include", "pragma", "error", "version",
]

static var _token_regex: RegEx


static func format(code: String) -> String:
	if _token_regex == null:
		_token_regex = RegEx.new()
		_token_regex.compile("\"[^\"]*\"|\\b\\d+(?:\\.\\d+)?\\b|\\b[A-Za-z_][A-Za-z0-9_]*\\b")
	var lines := code.split("\n")
	var out := PackedStringArray()
	for line in lines:
		out.append(_format_line(line))
	return "[color=%s]%s[/color]" % [COLOR_TEXT, "\n".join(out)]


static func _format_line(line: String) -> String:
	var comment_index := _comment_start(line)
	var code_part := line
	var comment_part := ""
	if comment_index != -1:
		code_part = line.substr(0, comment_index)
		comment_part = line.substr(comment_index)
	var result := _format_tokens(code_part)
	if not comment_part.is_empty():
		result += "[color=%s]%s[/color]" % [COLOR_COMMENT, _describe_only(comment_part)]
	return result


## 주석은 흐린 회색 한 덩어리로 두는 편이 읽기 좋다. 그래서 색은 건드리지 않고
## 설명만 물려 둔다 — 주석에서 이름만 언급되는 클래스도 올려 보면 뜻이 나온다.
static func _describe_only(text: String) -> String:
	var result := ""
	var cursor := 0
	for token_match in _token_regex.search_all(text):
		var token := token_match.get_string()
		result += _escape(text.substr(cursor, token_match.get_start() - cursor))
		if Glossary.has(token):
			result += "[hint=%s]%s[/hint]" % [Glossary.hint(token), _escape(token)]
		else:
			result += _escape(token)
		cursor = token_match.get_end()
	result += _escape(text.substr(cursor))
	return result


static func _comment_start(line: String) -> int:
	var slash_index := line.find("//")
	var hash_index := line.find("#")
	# GDScript에서 #은 주석이지만 셰이더의 #define·#ifdef는 엄연히 코드다.
	# 회색으로 눕혀 두면 컴파일 스위치가 주석처럼 보이는데, 그 스위치가 곧
	# 요점인 챕터가 있다. 전처리기 지시자는 건너뛰고 다음 #부터 주석으로 본다.
	while hash_index != -1 and _is_preprocessor(line, hash_index):
		hash_index = line.find("#", hash_index + 1)
	if hash_index == -1:
		return slash_index
	if slash_index == -1:
		return hash_index
	return mini(hash_index, slash_index)


static func _is_preprocessor(line: String, hash_index: int) -> bool:
	var rest := line.substr(hash_index + 1)
	for word in PREPROCESSOR:
		if rest.begins_with(word):
			return true
	return false


static func _format_tokens(text: String) -> String:
	var result := ""
	var cursor := 0
	for token_match in _token_regex.search_all(text):
		result += _escape(text.substr(cursor, token_match.get_start() - cursor))
		result += _format_token(token_match.get_string())
		cursor = token_match.get_end()
	result += _escape(text.substr(cursor))
	return result


static func _format_token(token: String) -> String:
	var color := ""
	if token.begins_with("\""):
		color = COLOR_STRING
	elif token.unicode_at(0) >= 48 and token.unicode_at(0) <= 57:
		color = COLOR_NUMBER
	elif Glossary.has(token):
		color = str(KIND_COLORS.get(Glossary.kind_of(token), ""))
	elif KEYWORDS.has(token):
		color = COLOR_KEYWORD
	elif token.unicode_at(0) >= 65 and token.unicode_at(0) <= 90:
		color = COLOR_TYPE
	var result := _escape(token)
	if not color.is_empty():
		result = "[color=%s]%s[/color]" % [color, result]
	if Glossary.has(token):
		# hint 값은 순수 텍스트다. 대괄호가 들어가면 bbcode 파서가 물어 버리므로
		# 사전 쪽에서 대괄호를 쓰지 않는다.
		result = "[hint=%s]%s[/hint]" % [Glossary.hint(token), result]
	return result


static func _escape(text: String) -> String:
	# "[lb]" 자체가 대괄호를 포함하므로 임시 문자를 거쳐 치환한다.
	return text.replace("[", char(1)).replace("]", "[rb]").replace(char(1), "[lb]")
