extends CharacterBody2D

# Скорость героя в пикселях в секунду.
const SPEED := 220.0

# Область, внутри которой герой может ходить. Её задаёт сцена бункера.
var move_area := Rect2(0, 0, 1152, 648)

# Куда герой смотрит (нужно, чтобы нарисовать его «лицо»).
var facing := Vector2.DOWN


# Вызывается много раз в секунду: здесь мы двигаем героя.
func _physics_process(_delta: float) -> void:
	var direction := get_move_direction()
	velocity = direction * SPEED
	move_and_slide()

	# Не даём выйти за стены комнаты
	position = position.clamp(move_area.position, move_area.end)

	# Запоминаем направление взгляда и перерисовываем героя
	if direction != Vector2.ZERO and direction != facing:
		facing = direction
		queue_redraw()


# Смотрит, какие клавиши нажаты, и возвращает направление движения.
func get_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.y += 1
	return direction.normalized()


# Рисует героя: круг (тело) и маленький кружок (куда он смотрит).
func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, Color(0.85, 0.65, 0.3))
	draw_circle(facing * 10, 5, Color(0.98, 0.9, 0.75))
