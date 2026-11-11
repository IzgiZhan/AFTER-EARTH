extends Node2D

# Надпись под кнопками, в которой показываем сообщения игроку.
var status_label: Label


# Запускается один раз, когда сцена появляется на экране.
func _ready() -> void:
	# Тёмный фон на весь экран
	var background := ColorRect.new()
	background.color = Color(0.07, 0.08, 0.09)
	background.size = get_viewport_rect().size
	add_child(background)

	# Название игры
	var title := Label.new()
	title.text = "AFTER EARTH"
	title.add_theme_font_size_override("font_size", 72)
	title.position = Vector2(80, 60)
	add_child(title)

	# Девиз под названием
	var subtitle := Label.new()
	subtitle.text = "Rebuild Humanity. Create a New Civilization."
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.position = Vector2(84, 160)
	add_child(subtitle)

	# Контейнер, который сам ставит кнопки друг под другом
	var menu := VBoxContainer.new()
	menu.position = Vector2(84, 250)
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)

	# Кнопка New Game
	var new_game_button := make_button("New Game")
	new_game_button.pressed.connect(on_new_game_pressed)
	menu.add_child(new_game_button)

	# Кнопки Continue и Load Game пока выключены: сохранений ещё нет
	var continue_button := make_button("Continue")
	continue_button.disabled = true
	menu.add_child(continue_button)

	var load_button := make_button("Load Game")
	load_button.disabled = true
	menu.add_child(load_button)

	# Кнопка выхода
	var quit_button := make_button("Quit")
	quit_button.pressed.connect(on_quit_pressed)
	menu.add_child(quit_button)

	# Строка для сообщений
	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.position = Vector2(84, 530)
	add_child(status_label)


# Создаёт одну кнопку меню с нужным текстом и размером.
func make_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(280, 52)
	button.add_theme_font_size_override("font_size", 24)
	return button


# Вызывается при нажатии New Game.
func on_new_game_pressed() -> void:
	status_label.text = "New Game: the bunker will be added in the next stage."


# Вызывается при нажатии Quit: закрывает игру.
func on_quit_pressed() -> void:
	get_tree().quit()
