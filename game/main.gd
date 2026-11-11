extends Node2D

# Этот код запускается один раз, когда сцена появляется на экране.
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
	title.position = Vector2(80, 80)
	add_child(title)

	# Девиз под названием
	var subtitle := Label.new()
	subtitle.text = "Rebuild Humanity. Create a New Civilization."
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.position = Vector2(84, 180)
	add_child(subtitle)
