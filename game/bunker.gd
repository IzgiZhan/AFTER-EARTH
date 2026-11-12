extends Node2D

const GameState = preload("res://game_state.gd")

# Комната бункера: положение (x, y) и размер (ширина, высота).
const ROOM := Rect2(176, 124, 800, 400)

# Толщина стен.
const WALL := 16.0

# Дверь наружу: середина верхней стены.
const DOOR := Vector2(576, 124)

var player
var hint: Label


# Запускается один раз при открытии сцены.
func _ready() -> void:
	# Возвращаем вид экрана в исходное положение после камеры на карте
	get_viewport().canvas_transform = Transform2D()

	# Создаём героя из файла player.gd и ставим в центр комнаты
	player = preload("res://player.gd").new()
	player.position = ROOM.get_center()
	player.move_area = ROOM.grow(-20)
	add_child(player)

	# Подсказка по управлению
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 20)
	hint.position = Vector2(176, 70)
	add_child(hint)


# Каждый кадр проверяем, стоит ли герой у двери.
func _process(_delta: float) -> void:
	if is_near_door():
		hint.text = "Press E to go outside"
	else:
		hint.text = "Bunker  |  Move: W A S D  |  Exit: yellow door  |  Menu: Esc"


func is_near_door() -> bool:
	return player.position.distance_to(DOOR) < 70.0


# Рисует фон, стены, пол и жёлтую дверь.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.04, 0.045, 0.05))
	draw_rect(ROOM.grow(WALL), Color(0.3, 0.32, 0.34))
	draw_rect(ROOM, Color(0.16, 0.17, 0.18))
	draw_rect(Rect2(DOOR.x - 30, DOOR.y - WALL, 60, WALL), Color(0.8, 0.62, 0.2))


# E у двери выводит наружу, Esc возвращает в меню.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E and is_near_door():
			go_outside()
		elif event.physical_keycode == KEY_ESCAPE:
			GameState.reset()
			get_tree().change_scene_to_file("res://main.tscn")


# Создаёт карту мира из файла world.gd и переключается на неё.
func go_outside() -> void:
	var world = preload("res://world.gd").new()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	queue_free()
