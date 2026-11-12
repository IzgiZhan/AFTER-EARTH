extends Node2D

const GameState = preload("res://game_state.gd")

const MAP := Rect2(0, 0, 3200, 2000)
const BUNKER_DOOR := Vector2(1600, 1000)
const REACH := 50.0
const RESOURCE_COUNT := 70
const RESOURCE_TYPES := ["Wood", "Iron", "Water", "Food"]
const SAFE_RADIUS := 220.0
const ZONE_CENTER := Vector2(2700, 500)
const ZONE_RADIUS := 420.0
const RUNNER_SPEED := 165.0
const ATTACK_RANGE := 70.0

var player
var hud
var night: CanvasModulate
var light: PointLight2D
var flash: ColorRect

# Три слоя рисования: земля (рисуется один раз), ресурсы, существа.
var ground_layer: Node2D
var resource_layer: Node2D
var actor_layer: Node2D

var rng := RandomNumberGenerator.new()
var resources: Array = []
var ground_spots: Array = []
var ruins: Array = []
var mutants: Array = []
var highlight := {}
var attack_cooldown := 0.0
var attack_flash := 0.0
var in_zone := false
var time := 0.0


func _ready() -> void:
	create_map()

	ground_layer = Node2D.new()
	ground_layer.draw.connect(draw_ground)
	add_child(ground_layer)

	resource_layer = Node2D.new()
	resource_layer.draw.connect(draw_resources)
	add_child(resource_layer)

	actor_layer = Node2D.new()
	actor_layer.draw.connect(draw_actors)
	add_child(actor_layer)

	var door_label := Label.new()
	door_label.text = "BUNKER"
	door_label.position = BUNKER_DOOR + Vector2(-34, -92)
	add_child(door_label)

	var zone_label := Label.new()
	zone_label.text = "RADIATION ZONE"
	zone_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.3))
	zone_label.position = ZONE_CENTER + Vector2(-70, -ZONE_RADIUS + 20)
	add_child(zone_label)

	player = preload("res://player.gd").new()
	player.position = BUNKER_DOOR + Vector2(0, 80)
	player.move_area = MAP.grow(-20)
	add_child(player)

	var camera := Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP.size.x)
	camera.limit_bottom = int(MAP.size.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	camera.make_current()

	# Пыль в воздухе вокруг героя
	var dust := CPUParticles2D.new()
	dust.amount = 70
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.local_coords = false
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(700, 420)
	dust.direction = Vector2(1, 0.2)
	dust.spread = 25.0
	dust.gravity = Vector2.ZERO
	dust.initial_velocity_min = 15.0
	dust.initial_velocity_max = 45.0
	dust.scale_amount_min = 1.5
	dust.scale_amount_max = 3.0
	dust.color = Color(0.85, 0.78, 0.6, 0.3)
	player.add_child(dust)

	# Пятно света вокруг героя: включается с наступлением темноты
	light = PointLight2D.new()
	light.texture = make_radial_texture(Color(1.0, 0.95, 0.8, 1.0), Color(0, 0, 0, 0), 0.0)
	light.texture_scale = 3.0
	light.energy = 0.0
	player.add_child(light)

	# Затемнение мира ночью
	night = CanvasModulate.new()
	add_child(night)

	# Затемнение по краям экрана и красная вспышка при ударе
	var overlay := CanvasLayer.new()
	add_child(overlay)

	var vignette := TextureRect.new()
	vignette.texture = make_radial_texture(Color(0, 0, 0, 0), Color(0, 0, 0, 0.55), 0.55)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.size = Vector2(1152, 648)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(vignette)

	flash = ColorRect.new()
	flash.color = Color(0.8, 0.05, 0.05, 0.0)
	flash.size = Vector2(1152, 648)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(flash)

	hud = preload("res://hud.gd").new()
	add_child(hud)
	hud.set_objective("Objective: gather Food and Water. Avoid the night.")
	hud.set_controls("WASD move | E interact | SPACE knife | F eat | R drink | I backpack | Esc menu")


# Создаёт круглую картинку с плавным переходом от центра к краю.
func make_radial_texture(center: Color, edge: Color, start: float) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, center)
	gradient.set_color(1, edge)
	gradient.set_offset(0, start)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	return texture


# Расставляет всё на карте. Число 2026 делает карту одинаковой каждый раз.
func create_map() -> void:
	var map_rng := RandomNumberGenerator.new()
	map_rng.seed = 2026

	for i in 160:
		ground_spots.append({
			"pos": Vector2(map_rng.randf_range(0, MAP.size.x), map_rng.randf_range(0, MAP.size.y)),
			"radius": map_rng.randf_range(20, 70),
		})

	for i in RESOURCE_COUNT:
		var pos := Vector2(map_rng.randf_range(60, MAP.size.x - 60), map_rng.randf_range(60, MAP.size.y - 60))
		var type_name: String = RESOURCE_TYPES[map_rng.randi_range(0, RESOURCE_TYPES.size() - 1)]
		if GameState.collected.has(i):
			continue
		if pos.distance_to(BUNKER_DOOR) < 160:
			continue
		resources.append({"id": i, "type": type_name, "pos": pos})

	for i in 10:
		var offset := Vector2.RIGHT.rotated(map_rng.randf_range(0.0, TAU)) * map_rng.randf_range(40.0, ZONE_RADIUS - 60.0)
		var id := RESOURCE_COUNT + i
		if GameState.collected.has(id):
			continue
		resources.append({"id": id, "type": "Iron", "pos": ZONE_CENTER + offset})

	for i in 14:
		var size := Vector2(map_rng.randf_range(90, 240), map_rng.randf_range(80, 200))
		var corner := Vector2(map_rng.randf_range(60, MAP.size.x - 300), map_rng.randf_range(60, MAP.size.y - 260))
		var ruin := Rect2(corner, size)
		if ruin.get_center().distance_to(BUNKER_DOOR) < 320:
			continue
		ruins.append(ruin)

	for i in 9:
		var pos := Vector2(map_rng.randf_range(100, MAP.size.x - 100), map_rng.randf_range(100, MAP.size.y - 100))
		if pos.distance_to(BUNKER_DOOR) < 600:
			continue
		mutants.append({
			"pos": pos, "health": 100.0, "dir": Vector2.ZERO,
			"face": Vector2.RIGHT, "timer": 0.0, "cooldown": 0.0,
		})


func _process(delta: float) -> void:
	time += delta
	GameState.tick(delta, true)

	var now_in_zone: bool = player.position.distance_to(ZONE_CENTER) < ZONE_RADIUS
	if now_in_zone:
		GameState.change_stat("Radiation", 7.0 * delta)
		if not in_zone:
			hud.show_message("WARNING: radiation zone!", 3.0)
	in_zone = now_in_zone

	update_mutants(delta)

	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_flash = maxf(0.0, attack_flash - delta)

	# День и ночь: мир темнеет, а свет героя разгорается
	var daylight := GameState.get_daylight()
	night.color = Color(0.2, 0.22, 0.38).lerp(Color.WHITE, daylight)
	light.energy = (1.0 - daylight) * 1.2

	# Красная вспышка постепенно гаснет
	var flash_color := flash.color
	flash_color.a = maxf(0.0, flash_color.a - delta)
	flash.color = flash_color

	# Подсказка и подсветка ближайшего ресурса
	var hint := ""
	highlight = {}
	if is_near_door():
		hint = "Press E to enter the bunker"
	else:
		var target := find_nearby_resource()
		if not target.is_empty():
			hint = "Press E to collect " + str(target["type"])
			highlight = target
	hud.set_hint(hint)

	if float(GameState.stats["Health"]) <= 0.0:
		set_process(false)
		GameState.apply_defeat()
		get_tree().change_scene_to_file("res://bunker.tscn")
		return

	actor_layer.queue_redraw()


# Двигает мутантов: они бродят, а заметив героя, бегут к нему.
func update_mutants(delta: float) -> void:
	var chase_range := 520.0 if GameState.is_night() else 340.0
	var player_safe: bool = player.position.distance_to(BUNKER_DOOR) < SAFE_RADIUS

	for mutant in mutants:
		var pos: Vector2 = mutant["pos"]
		var to_player: Vector2 = player.position - pos
		var distance := to_player.length()
		var direction: Vector2 = mutant["dir"]
		var speed := 60.0

		if distance < chase_range and not player_safe:
			direction = to_player.normalized()
			speed = RUNNER_SPEED
		else:
			mutant["timer"] -= delta
			if float(mutant["timer"]) <= 0.0:
				mutant["timer"] = rng.randf_range(1.5, 4.0)
				mutant["dir"] = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU))
				direction = mutant["dir"]

		if direction != Vector2.ZERO:
			mutant["face"] = direction
		pos += direction * speed * delta

		var from_door := pos - BUNKER_DOOR
		if from_door.length() < SAFE_RADIUS:
			pos = BUNKER_DOOR + from_door.normalized() * SAFE_RADIUS
		pos = pos.clamp(MAP.position + Vector2(20, 20), MAP.end - Vector2(20, 20))
		mutant["pos"] = pos

		mutant["cooldown"] = maxf(0.0, float(mutant["cooldown"]) - delta)
		if distance < 30.0 and float(mutant["cooldown"]) <= 0.0:
			mutant["cooldown"] = 1.0
			GameState.change_stat("Health", -9.0)
			hud.show_message("A Runner hits you!")
			var flash_color := flash.color
			flash_color.a = 0.4
			flash.color = flash_color


func is_near_door() -> bool:
	return player.position.distance_to(BUNKER_DOOR) < REACH + 10.0


func find_nearby_resource() -> Dictionary:
	var nearest := {}
	var nearest_distance := REACH
	for item in resources:
		var distance: float = player.position.distance_to(item["pos"])
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
	return nearest


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode
		if key == KEY_E:
			interact()
		elif key == KEY_SPACE:
			attack()
		elif key == KEY_F:
			hud.show_message(GameState.eat())
		elif key == KEY_R:
			hud.show_message(GameState.drink())
		elif key == KEY_I:
			hud.toggle_inventory()
		elif key == KEY_ESCAPE:
			GameState.reset()
			get_tree().change_scene_to_file("res://main.tscn")


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
		resource_layer.queue_redraw()
		hud.show_message("+1 " + str(target["type"]))
	else:
		hud.show_message("Backpack is full")


func attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.45
	attack_flash = 0.15
	GameState.change_stat("Energy", -1.0)

	for mutant in mutants.duplicate():
		var pos: Vector2 = mutant["pos"]
		var away: Vector2 = pos - player.position
		if away.length() < ATTACK_RANGE:
			mutant["health"] -= 34.0
			mutant["pos"] = pos + away.normalized() * 50.0
			if float(mutant["health"]) <= 0.0:
				mutants.erase(mutant)
				hud.show_message("Runner defeated")


# ---------- РИСОВАНИЕ ЗЕМЛИ (один раз) ----------

func rand_point(r: RandomNumberGenerator) -> Vector2:
	return Vector2(r.randf_range(0, MAP.size.x), r.randf_range(0, MAP.size.y))


func draw_ground() -> void:
	var g := ground_layer
	var r := RandomNumberGenerator.new()
	r.seed = 77

	# Почва и пятна
	g.draw_rect(MAP, Color(0.24, 0.22, 0.17))
	for spot in ground_spots:
		g.draw_circle(spot["pos"], spot["radius"], Color(0.21, 0.195, 0.15))
	for i in 120:
		g.draw_circle(rand_point(r), r.randf_range(15, 50), Color(0.28, 0.25, 0.19, 0.6))

	# Две старые дороги
	draw_road(g, r, Rect2(0, 1130, MAP.size.x, 96), true)
	draw_road(g, r, Rect2(2250, 0, 96, MAP.size.y), false)

	# Сухая трава
	for i in 700:
		var p := rand_point(r)
		var c := Color(0.3, 0.36, 0.2).lerp(Color(0.42, 0.38, 0.22), r.randf())
		g.draw_line(p, p + Vector2(-3, -7), c, 1.5)
		g.draw_line(p, p + Vector2(0, -9), c, 1.5)
		g.draw_line(p, p + Vector2(3, -6), c, 1.5)

	# Камешки с тенью
	for i in 260:
		var p := rand_point(r)
		g.draw_circle(p + Vector2(1, 2), 3, Color(0, 0, 0, 0.25))
		g.draw_circle(p, r.randf_range(1.5, 3.5), Color(0.42, 0.41, 0.4))

	# Заражённая земля и светящиеся лужи в радиационной зоне
	g.draw_circle(ZONE_CENTER, ZONE_RADIUS, Color(0.35, 0.5, 0.15, 0.25))
	for i in 16:
		var p := ZONE_CENTER + Vector2.RIGHT.rotated(r.randf_range(0.0, TAU)) * r.randf_range(30.0, ZONE_RADIUS - 40.0)
		var size := r.randf_range(10, 26)
		g.draw_circle(p, size, Color(0.5, 0.85, 0.2, 0.45))
		g.draw_circle(p, size * 0.5, Color(0.8, 1.0, 0.5, 0.5))

	for ruin in ruins:
		draw_ruin(g, r, ruin)

	# Вход в бункер: бетонная площадка, жёлтая рамка, люк
	g.draw_rect(Rect2(BUNKER_DOOR - Vector2(52, 50), Vector2(120, 120)), Color(0, 0, 0, 0.3))
	g.draw_rect(Rect2(BUNKER_DOOR - Vector2(60, 60), Vector2(120, 120)), Color(0.36, 0.37, 0.38))
	g.draw_rect(Rect2(BUNKER_DOOR - Vector2(52, 52), Vector2(104, 104)), Color(0.85, 0.7, 0.15), false, 5.0)
	g.draw_circle(BUNKER_DOOR, 32, Color(0.2, 0.21, 0.23))
	g.draw_arc(BUNKER_DOOR, 32, 0.0, TAU, 32, Color(0.5, 0.52, 0.55), 3.0)
	g.draw_line(BUNKER_DOOR + Vector2(-12, 0), BUNKER_DOOR + Vector2(12, 0), Color(0.6, 0.62, 0.65), 4.0)

	g.draw_rect(MAP, Color(0.05, 0.05, 0.05), false, 12.0)


func draw_road(g: Node2D, r: RandomNumberGenerator, area: Rect2, horizontal: bool) -> void:
	g.draw_rect(area.grow(5), Color(0.17, 0.16, 0.14))
	g.draw_rect(area, Color(0.2, 0.2, 0.21))

	# Прерывистая разметка, местами стёртая
	var length := area.size.x if horizontal else area.size.y
	var step := 0.0
	while step < length:
		if r.randf() < 0.7:
			if horizontal:
				g.draw_rect(Rect2(area.position.x + step, area.get_center().y - 2, 34, 4), Color(0.75, 0.72, 0.6, 0.7))
			else:
				g.draw_rect(Rect2(area.get_center().x - 2, area.position.y + step, 4, 34), Color(0.75, 0.72, 0.6, 0.7))
		step += 70.0

	# Трещины и выбоины
	for i in 40:
		var p := Vector2(r.randf_range(area.position.x, area.end.x), r.randf_range(area.position.y, area.end.y))
		var q := p + Vector2(r.randf_range(-30, 30), r.randf_range(-30, 30))
		g.draw_line(p, q, Color(0.1, 0.1, 0.1), 2.0)
		if i % 4 == 0:
			g.draw_circle(p, r.randf_range(8, 18), Color(0.24, 0.22, 0.17))


func draw_ruin(g: Node2D, r: RandomNumberGenerator, area: Rect2) -> void:
	# Тень и бетонный пол
	g.draw_rect(Rect2(area.position + Vector2(10, 12), area.size), Color(0, 0, 0, 0.3))
	g.draw_rect(area, Color(0.3, 0.3, 0.31))

	# Плитка
	var line := Color(0.25, 0.25, 0.26)
	var x := area.position.x + 24.0
	while x < area.end.x:
		g.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), line, 1.0)
		x += 24.0
	var y := area.position.y + 24.0
	while y < area.end.y:
		g.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), line, 1.0)
		y += 24.0

	# Стены с проломами
	var wall := Color(0.45, 0.43, 0.4)
	var t := 0.0
	while t < area.size.x:
		var w := minf(30.0, area.size.x - t)
		if r.randf() < 0.75:
			g.draw_rect(Rect2(area.position.x + t, area.position.y - 5, w, 10), wall)
		if r.randf() < 0.75:
			g.draw_rect(Rect2(area.position.x + t, area.end.y - 5, w, 10), wall)
		t += 30.0
	t = 0.0
	while t < area.size.y:
		var h := minf(30.0, area.size.y - t)
		if r.randf() < 0.75:
			g.draw_rect(Rect2(area.position.x - 5, area.position.y + t, 10, h), wall)
		if r.randf() < 0.75:
			g.draw_rect(Rect2(area.end.x - 5, area.position.y + t, 10, h), wall)
		t += 30.0

	# Обломки
	for i in 10:
		var p := Vector2(r.randf_range(area.position.x - 20, area.end.x + 20), r.randf_range(area.position.y - 20, area.end.y + 20))
		g.draw_circle(p, r.randf_range(3, 8), Color(0.38, 0.37, 0.35))


# ---------- РИСОВАНИЕ РЕСУРСОВ ----------

func draw_resources() -> void:
	var g := resource_layer
	for item in resources:
		var pos: Vector2 = item["pos"]
		var r := RandomNumberGenerator.new()
		r.seed = int(item["id"]) * 977 + 13
		match str(item["type"]):
			"Wood":
				draw_tree(g, r, pos)
			"Iron":
				draw_rock(g, r, pos)
			"Water":
				draw_puddle(g, r, pos)
			"Food":
				draw_bush(g, r, pos)


func draw_tree(g: Node2D, r: RandomNumberGenerator, pos: Vector2) -> void:
	g.draw_circle(pos + Vector2(10, 12), 24, Color(0, 0, 0, 0.3))
	g.draw_circle(pos, 7, Color(0.35, 0.24, 0.14))
	for i in 5:
		var offset := Vector2(r.randf_range(-11, 11), r.randf_range(-11, 11))
		var color := Color(0.16, 0.32, 0.17).lerp(Color(0.3, 0.45, 0.2), r.randf())
		g.draw_circle(pos + offset, r.randf_range(12, 18), color)
	g.draw_circle(pos + Vector2(-6, -7), 6, Color(0.42, 0.56, 0.28, 0.7))


func draw_rock(g: Node2D, r: RandomNumberGenerator, pos: Vector2) -> void:
	var points := PackedVector2Array()
	var top := PackedVector2Array()
	for i in 7:
		var corner := Vector2.RIGHT.rotated(TAU * i / 7.0) * r.randf_range(12, 19)
		points.append(pos + corner)
		top.append(pos + corner * 0.55 + Vector2(-2, -3))
	g.draw_circle(pos + Vector2(6, 8), 17, Color(0, 0, 0, 0.3))
	g.draw_colored_polygon(points, Color(0.36, 0.36, 0.39))
	g.draw_colored_polygon(top, Color(0.52, 0.52, 0.55))
	for i in 3:
		g.draw_circle(pos + Vector2(r.randf_range(-9, 9), r.randf_range(-9, 9)), r.randf_range(2, 4), Color(0.72, 0.4, 0.18))


func draw_puddle(g: Node2D, r: RandomNumberGenerator, pos: Vector2) -> void:
	g.draw_circle(pos, 24, Color(0.15, 0.14, 0.11, 0.6))
	for i in 3:
		g.draw_circle(pos + Vector2(r.randf_range(-8, 8), r.randf_range(-6, 6)), r.randf_range(11, 16), Color(0.16, 0.36, 0.55))
	g.draw_circle(pos + Vector2(-2, -1), 9, Color(0.28, 0.52, 0.72))
	g.draw_circle(pos + Vector2(-6, -5), 2.5, Color(0.9, 0.96, 1.0, 0.9))


func draw_bush(g: Node2D, r: RandomNumberGenerator, pos: Vector2) -> void:
	g.draw_circle(pos + Vector2(6, 8), 17, Color(0, 0, 0, 0.3))
	for i in 5:
		var offset := Vector2(r.randf_range(-8, 8), r.randf_range(-8, 8))
		var color := Color(0.2, 0.36, 0.18).lerp(Color(0.34, 0.5, 0.24), r.randf())
		g.draw_circle(pos + offset, r.randf_range(8, 12), color)
	for i in 6:
		var berry := pos + Vector2(r.randf_range(-11, 11), r.randf_range(-11, 11))
		g.draw_circle(berry, 3, Color(0.8, 0.12, 0.18))
		g.draw_circle(berry + Vector2(-1, -1), 1, Color(1.0, 0.7, 0.7))


# ---------- РИСОВАНИЕ СУЩЕСТВ (каждый кадр) ----------

func draw_actors() -> void:
	var g := actor_layer

	# Пульсирующая граница радиационной зоны
	var pulse := 0.4 + 0.2 * sin(time * 2.0)
	g.draw_arc(ZONE_CENTER, ZONE_RADIUS, 0.0, TAU, 96, Color(0.6, 0.95, 0.2, pulse), 4.0)

	# Кольцо вокруг ресурса, который можно собрать
	if not highlight.is_empty():
		g.draw_arc(highlight["pos"], 30.0, 0.0, TAU, 32, Color(1, 1, 1, 0.7), 2.0)

	for mutant in mutants:
		var pos: Vector2 = mutant["pos"]
		var face: Vector2 = mutant["face"]
		var step := sin(time * 10.0 + pos.x)

		g.draw_circle(pos + Vector2(4, 6), 16, Color(0, 0, 0, 0.3))
		g.draw_set_transform(pos, face.angle(), Vector2.ONE)

		# Длинные руки
		g.draw_line(Vector2(2, -10), Vector2(20.0 + step * 4.0, -14), Color(0.5, 0.45, 0.42), 4.0)
		g.draw_line(Vector2(2, 10), Vector2(20.0 - step * 4.0, 14), Color(0.5, 0.45, 0.42), 4.0)
		# Туловище
		g.draw_circle(Vector2(-3, 0), 13, Color(0.4, 0.12, 0.14))
		g.draw_circle(Vector2(-6, 0), 8, Color(0.3, 0.08, 0.1))
		# Голова со светящимися глазами
		g.draw_circle(Vector2(9, 0), 8, Color(0.62, 0.6, 0.52))
		g.draw_circle(Vector2(13, -3), 2, Color(1.0, 0.85, 0.1))
		g.draw_circle(Vector2(13, 3), 2, Color(1.0, 0.85, 0.1))

		g.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		var health: float = mutant["health"]
		if health < 100.0:
			g.draw_rect(Rect2(pos + Vector2(-16, -30), Vector2(32, 4)), Color(0, 0, 0, 0.6))
			g.draw_rect(Rect2(pos + Vector2(-16, -30), Vector2(32.0 * health / 100.0, 4)), Color(0.9, 0.2, 0.2))

	# Взмах ножа перед героем
	if attack_flash > 0.0:
		var angle: float = player.facing_angle
		g.draw_arc(player.position, 55.0, angle - 1.0, angle + 1.0, 16, Color(1, 1, 1, 0.8), 5.0)
