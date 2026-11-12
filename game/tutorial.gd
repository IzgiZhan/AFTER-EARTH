extends RefCounted

# Шаги обучения по порядку. Шаг считается пройденным, когда появляется
# флаг "until". level и cell: куда показывает стрелка.
const STEPS := [
	{"until": "moved", "text": "Tutorial: walk with W A S D or the arrow keys."},
	{"until": "note1", "level": 0, "cell": Vector2i(3, 15), "text": "Tutorial: follow the arrow to the desk and press E to read the note."},
	{"until": "crowbar", "level": 0, "cell": Vector2i(3, 6), "text": "Tutorial: cross the corridor to the workshop and take the crowbar."},
	{"until": "cleared_a", "level": 0, "cell": Vector2i(18, 10), "text": "Tutorial: clear the rubble at the laboratory door with the crowbar (E)."},
	{"until": "fuse", "level": 0, "cell": Vector2i(24, 6), "text": "Tutorial: search the research tables in the laboratory."},
	{"until": "key", "level": 0, "cell": Vector2i(36, 10), "text": "Tutorial: go through the laboratory to the bedroom and search the bunk."},
	{"until": "note2", "level": 0, "cell": Vector2i(24, 19), "text": "Tutorial: read the note in the control room."},
	{"until": "note3", "level": 0, "cell": Vector2i(26, 2), "text": "Tutorial: read the note at the airlock."},
	{"until": "seen_level_1", "level": 0, "cell": Vector2i(20, 24), "text": "Tutorial: the elevator has a fuse now. Ride it down to level 2."},
	{"until": "note4", "level": 1, "cell": Vector2i(3, 6), "text": "Tutorial: read the note in the canteen."},
	{"until": "cleared_b", "level": 1, "cell": Vector2i(15, 19), "text": "Tutorial: clear the rubble in the corridor."},
	{"until": "cleared_k", "level": 1, "cell": Vector2i(12, 16), "text": "Tutorial: unlock the main storage with the key."},
	{"until": "lever", "level": 1, "cell": Vector2i(5, 19), "text": "Tutorial: search the crates for the lift lever."},
	{"until": "pickaxe", "level": 2, "cell": Vector2i(4, 6), "text": "Tutorial: ride the cargo lift down and take a pickaxe."},
	{"until": "coal", "level": 2, "cell": Vector2i(3, 19), "text": "Tutorial: mine coal in the west face."},
	{"until": "power", "level": 2, "cell": Vector2i(24, 7), "text": "Tutorial: start the generator with the coal."},
]

# Что показывать, когда обучение пройдено.
const FINAL := {"level": 0, "cell": Vector2i(20, 1), "text": "Objective: the bunker has power. Go outside through the airlock on level 1."}

const TEXTS := [
	["Tutorial: walk with W A S D or the arrow keys.", "Обучение: ходите клавишами W A S D или стрелками."],
	["Tutorial: follow the arrow to the desk and press E to read the note.", "Обучение: идите по стрелке к столу и нажмите E, чтобы прочитать записку."],
	["Tutorial: cross the corridor to the workshop and take the crowbar.", "Обучение: пройдите через коридор в мастерскую и возьмите лом."],
	["Tutorial: clear the rubble at the laboratory door with the crowbar (E).", "Обучение: разберите ломом завал у двери лаборатории (E)."],
	["Tutorial: search the research tables in the laboratory.", "Обучение: обыщите столы в лаборатории."],
	["Tutorial: go through the laboratory to the bedroom and search the bunk.", "Обучение: пройдите через лабораторию в спальню и обыщите койку."],
	["Tutorial: read the note in the control room.", "Обучение: прочитайте записку в кабинете управления."],
	["Tutorial: read the note at the airlock.", "Обучение: прочитайте записку у гермошлюза."],
	["Tutorial: the elevator has a fuse now. Ride it down to level 2.", "Обучение: в лифте теперь есть предохранитель. Спуститесь на уровень 2."],
	["Tutorial: read the note in the canteen.", "Обучение: прочитайте записку в столовой."],
	["Tutorial: clear the rubble in the corridor.", "Обучение: разберите завал в коридоре."],
	["Tutorial: unlock the main storage with the key.", "Обучение: откройте главный склад ключом."],
	["Tutorial: search the crates for the lift lever.", "Обучение: найдите в ящиках рычаг подъёмника."],
	["Tutorial: ride the cargo lift down and take a pickaxe.", "Обучение: спуститесь на грузовом подъёмнике и возьмите кирку."],
	["Tutorial: mine coal in the west face.", "Обучение: добудьте уголь в западном забое."],
	["Tutorial: start the generator with the coal.", "Обучение: запустите генератор на угле."],
	["Objective: the bunker has power. Go outside through the airlock on level 1.", "Цель: в бункере есть электричество. Выйдите наружу через гермошлюз на уровне 1."],
]

static var registered := false


static func register_translations() -> void:
	if registered:
		return
	registered = true
	var ru := Translation.new()
	ru.locale = "ru"
	for row in TEXTS:
		ru.add_message(row[0], row[1])
	TranslationServer.add_translation(ru)


# Возвращает первый непройденный шаг.
static func current_step(flags: Dictionary) -> Dictionary:
	for step in STEPS:
		if not flags.has(step["until"]):
			return step
	return FINAL
