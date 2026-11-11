extends Node2D

# Комната бункера: положение (x, y) и размер (ширина, высота).
const ROOM := Rect2(176, 124, 800, 400)

# Толщина стен.
const WALL := 16.0


# Запускается один раз при открытии сцены.
func _ready() -> void:
	# Создаём героя из файла player.gd и ставим в центр комнаты
	var player = preload("res://player.gd").new()
	player.position = ROOM.get_center()
	player.move_area = ROOM.grow(-20)
	add_child(player)

	# Подсказка по управлению
	var hint := Label.new()
	hint.text = "Bunker  |  Move: W A S D or arrows  |  Menu: Esc"
	hint.add_theme_font_size_override("font_size", 20)
	hint.position = Vector2(176, 70)
	add_child(hint)


# Рисует фон, стены и пол комнаты.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.04, 0.045, 0.05))
	draw_rect(ROOM.grow(WALL), Color(0.3, 0.32, 0.34))
	draw_rect(ROOM, Color(0.16, 0.17, 0.18))


# Esc возвращает в главное меню.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://main.tscn")
