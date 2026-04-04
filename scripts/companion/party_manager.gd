extends Node
## PartyManager — Autoload 싱글턴.
## 편성(파티) 상태를 저장하고 씬 전환 후에도 유지.

const MAX_PARTY_SIZE = 2

var selected_party: Array[String] = []  # imagen_id 배열

signal party_changed(party: Array[String])

func _ready() -> void:
	load_saved_party()

func set_party(imagen_ids: Array[String]) -> void:
	selected_party = []
	for id in imagen_ids.slice(0, MAX_PARTY_SIZE):
		selected_party.append(id)
	party_changed.emit(selected_party)
	SaveManager.save_last_party(selected_party)

func get_party() -> Array:
	var result: Array = []
	for id in selected_party:
		if ImagenDatabase == null:
			continue
		var data = ImagenDatabase.get_imagen(id)
		if data:
			result.append(data)
	return result

func load_saved_party() -> void:
	selected_party = SaveManager.get_last_party()

func clear_party() -> void:
	selected_party.clear()
	SaveManager.save_last_party([])
	party_changed.emit(selected_party)
