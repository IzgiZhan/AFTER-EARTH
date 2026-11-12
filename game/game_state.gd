extends RefCounted

# Сколько предметов помещается в рюкзак.
const CAPACITY := 50

# Что лежит в рюкзаке.
static var inventory := {"Wood": 0, "Iron": 0, "Water": 0, "Food": 0}

# Номера ресурсов, которые уже собраны на карте.
static var collected := {}


# Начинает игру заново: пустой рюкзак, все ресурсы на месте.
static func reset() -> void:
	inventory = {"Wood": 0, "Iron": 0, "Water": 0, "Food": 0}
	collected = {}


# Считает, сколько всего предметов в рюкзаке.
static func total() -> int:
	var sum := 0
	for amount in inventory.values():
		sum += int(amount)
	return sum


# Кладёт предмет в рюкзак. Возвращает false, если места нет.
static func add(item: String, amount: int) -> bool:
	if total() + amount > CAPACITY:
		return false
	inventory[item] += amount
	return true
