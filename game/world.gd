extends Node2D

const GameState = preload("res://game_state.gd")

# Размер карты, место входа в бункер и дальность взаимодействия.
const MAP := Rect2(0, 0, 3200, 2000)
const BUNKER_DOOR := Vector2(1600, 1000)
const REACH := 50.0
const RESOURCE_COUNT := 70
const RESOURCE_TYPES := ["Wood", "Iron", "Water", "Food"]

var player
var resources: Array = []
var ground_spots: Array = []
var resource_label: Label
var hint_label: Label
var message_label: Label
var inventory_panel: PanelContainer
var inventory_text: Label
var message_time := 0.0


func _ready() -> void:
	create_map()

	# Надпись над входом в бункер
	var door_label := Label.new()
	door_label.text = "BUNKER"
	door_label.position = BUNKER_DOOR + Vector2(-34, -72)
	add_child(door_label)

	# Герой появляется рядом со входом
	player = preload("res://player.gd").new()
	player.position = BUNKER_DOOR + Vector2(0, 70)
	player.move_area = MAP.grow(-20)
	add_child(player)

	# Камера прикреплена к герою и не выходит за края карты
	var camera := Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP.size.x)
	camera.limit_bottom = int(MAP.size.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()

	create_hud()
	update_hud()


# Расставляет пятна на земле и ресурсы. Число 2026 делает карту
# одинаковой при каждом запуске.
func create_map() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026

	for i in 160:
		ground_spots.append({
			"pos": Vector2(rng.randf_range(0, MAP.size.x), rng.randf_range(0, MAP.size.y)),
			"radius": rng.randf_range(20, 70),
		})

	for i in RESOURCE_COUNT:
		var pos := Vector2(rng.randf_range(60, MAP.size.x - 60), rng.randf_range(60, MAP.size.y - 60))
		var type_name: String = RESOURCE_TYPES[rng.randi_range(0, RESOURCE_TYPES.size() - 1)]
		if GameState.collected.has(i):
			continue
		if pos.distance_to(BUNKER_DOOR) < 160:
			continue
		resources.append({"id": i, "type": type_name, "pos": pos})


# Создаёт надписи на экране. CanvasLayer держит их на месте,
# когда камера движется.
func create_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	resource_label = make_label(20)
	resource_label.position = Vector2(16, 12)
	hud.add_child(resource_label)

	message_label = make_label(24)
	message_label.position = Vector2(0, 70)
	message_label.size = Vector2(1152, 34)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(message_label)

	hint_label = make_label(22)
	hint_label.position = Vector2(0, 560)
	hint_label.size = Vector2(1152, 32)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(hint_label)

	var controls := make_label(16)
	controls.text = "Move: W A S D   |   E: interact   |   I: inventory   |   Esc: menu"
	controls.position = Vector2(16, 616)
	hud.add_child(controls)

	inventory_panel = PanelContainer.new()
	inventory_panel.position = Vector2(376, 164)
	inventory_panel.custom_minimum_size = Vector2(400, 320)
	inventory_panel.visible = false
	hud.add_child(inventory_panel)

	inventory_text = Label.new()
	inventory_text.add_theme_font_size_override("font_size", 22)
	inventory_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_panel.add_child(inventory_text)


# Создаёт надпись с чёрной обводкой, чтобы текст читался на любом фоне.
func make_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label


# Обновляет цифры ресурсов на экране и в окне инвентаря.
func update_hud() -> void:
	var inv: Dictionary = GameState.inventory
	resource_label.text = "Wood: %d   Iron: %d   Water: %d   Food: %d   |   Backpack: %d / %d" % [
		inv["Wood"], inv["Iron"], inv["Water"], inv["Food"], GameState.total(), GameState.CAPACITY
	]
	inventory_text.text = "INVENTORY\n\nWood: %d\nIron: %d\nWater: %d\nFood: %d\n\nBackpack: %d / %d\n\nPress I to close" % [
		inv["Wood"], inv["Iron"], inv["Water"], inv["Food"], GameState.total(), GameState.CAPACITY
	]


# Вызывается каждый кадр: показывает подсказку и убирает старые сообщения.
func _process(delta: float) -> void:
	var hint := ""
	if is_near_door():
		hint = "Press E to enter the bunker"
	else:
		var target := find_nearby_resource()
		if not target.is_empty():
			hint = "Press E to collect " + str(target["type"])
	hint_label.text = hint

	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.text = ""


func is_near_door() -> bool:
	return player.position.distance_to(BUNKER_DOOR) < REACH + 10.0


# Ищет ближайший ресурс рядом с героем. Если рядом ничего нет,
# возвращает пустой словарь.
func find_nearby_resource() -> Dictionary:
	var nearest := {}
	var nearest_distance := REACH
	for item in resources:
		var distance: float = player.position.distance_to(item["pos"])
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
	return nearest


# Обработка клавиш E, I и Esc.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_E:
			interact()
		elif event.physical_keycode == KEY_I:
			inventory_panel.visible = not inventory_panel.visible
		elif event.physical_keycode == KEY_ESCAPE:
			GameState.reset()
			get_tree().change_scene_to_file("res://main.tscn")


# Клавиша E: войти в бункер или собрать ресурс.
func interact() -> void:
	if is_near_door():
		get_tree().change_scene_to_file("res://bunker.tscn")
		return

	var target := find_nearby_resource()
	if target.is_empty():
		return

	if GameState.add(str(target["type"]), 1):
		GameState.collected[target["id"]] = true
		resources.erase(target)
		queue_redraw()
		show_message("+1 " + str(target["type"]))
	else:
		show_message("Backpack is full")
	update_hud()


# Показывает сообщение в верхней части экрана на две секунды.
func show_message(text: String) -> void:
	message_label.text = text
	message_time = 2.0


# Рисует землю, вход в бункер и все ресурсы.
func _draw() -> void:
	draw_rect(MAP, Color(0.23, 0.22, 0.17))
	for spot in ground_spots:
		draw_circle(spot["pos"], spot["radius"], Color(0.2, 0.19, 0.15))
	draw_rect(MAP, Color(0.08, 0.08, 0.08), false, 8.0)

	draw_rect(Rect2(BUNKER_DOOR - Vector2(40, 40), Vector2(80, 80)), Color(0.3, 0.32, 0.34))
	draw_rect(Rect2(BUNKER_DOOR - Vector2(18, 18), Vector2(36, 36)), Color(0.08, 0.08, 0.09))

	for item in resources:
		draw_resource(item["type"], item["pos"])


# Рисует один ресурс. У каждого типа свой вид.
func draw_resource(type_name: String, pos: Vector2) -> void:
	match type_name:
		"Wood":
			draw_circle(pos, 20, Color(0.2, 0.4, 0.2))
			draw_circle(pos, 6, Color(0.4, 0.27, 0.15))
		"Iron":
			draw_circle(pos, 14, Color(0.4, 0.4, 0.43))
			draw_circle(pos + Vector2(4, -3), 5, Color(0.7, 0.4, 0.2))
		"Water":
			draw_circle(pos, 16, Color(0.2, 0.45, 0.7))
			draw_circle(pos + Vector2(-4, -4), 4, Color(0.6, 0.8, 0.95))
		"Food":
			draw_circle(pos, 14, Color(0.3, 0.5, 0.25))
			draw_circle(pos + Vector2(-5, -3), 3, Color(0.8, 0.15, 0.2))
			draw_circle(pos + Vector2(5, 3), 3, Color(0.8, 0.15, 0.2))
