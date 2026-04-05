class_name Shop
extends CanvasLayer
## 상점 화면.

const ITEM_CARD_SCENE := "res://scenes/ui/shop_item_card.tscn"
const ChapterUnlockScript = preload("res://scripts/data/chapter_unlock.gd")

@onready var _currency_label: Label = $VBox/TopBar/CurrencyLabel
@onready var _stamina_label: Label = $VBox/TopBar/StaminaLabel
@onready var _tab_currency_btn: Button = $VBox/TabBar/CurrencyTabButton
@onready var _tab_stamina_btn: Button = $VBox/TabBar/StaminaTabButton
@onready var _tab_chapter_btn: Button = $VBox/TabBar/ChapterTabButton
@onready var _scroll: ScrollContainer = $VBox/ScrollContainer
@onready var _item_list: VBoxContainer = $VBox/ScrollContainer/ItemList
@onready var _back_btn: Button = $VBox/BackButton
@onready var _msg_label: Label = $VBox/MsgLabel

var _products: Dictionary = {}
var _current_tab: String = "stamina"

func _ready() -> void:
	_tab_currency_btn.pressed.connect(func(): _show_tab("currency"))
	_tab_stamina_btn.pressed.connect(func(): _show_tab("stamina"))
	_tab_chapter_btn.pressed.connect(func(): _show_tab("chapter"))
	_back_btn.pressed.connect(_on_back_pressed)
	SaveManager.connect("tree_entered", _refresh_header)
	StaminaManager.stamina_changed.connect(func(_c, _m): _refresh_header())
	_products = ShopManager.get_products()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_refresh()

func _refresh() -> void:
	_refresh_header()
	_show_tab(_current_tab)

func _refresh_header() -> void:
	_currency_label.text = "💰 %d" % SaveManager.get_currency()
	_stamina_label.text = "⚡ %d/%d" % [StaminaManager.current_stamina, StaminaManager.max_stamina]

func _show_tab(tab: String) -> void:
	_current_tab = tab
	_refresh_header()
	for child in _item_list.get_children():
		child.queue_free()
	_msg_label.visible = false

	match tab:
		"currency":
			_build_currency_tab()
		"stamina":
			_build_stamina_tab()
		"chapter":
			_build_chapter_tab()

func _build_currency_tab() -> void:
	for p in _products.get("currency_products", []):
		var card = _make_card()
		var badge = p.get("badge", "")
		card.setup(p["id"], "💰", "재화 %d개" % p["amount"], p["price_display"], true, badge)
		card.purchase_requested.connect(func(pid): _on_buy_currency(pid))
		_item_list.add_child(card)

func _build_stamina_tab() -> void:
	for p in _products.get("stamina_products", []):
		var cost = p["cost_currency"]
		var can_buy = SaveManager.get_currency() >= cost
		var label = p.get("label", "")
		var name_text = "행동력 %d개%s" % [p["amount"], (" (%s)" % label) if label else ""]
		var card = _make_card()
		card.setup(p["id"], "⚡", name_text, "💰 %d" % cost, can_buy)
		card.purchase_requested.connect(func(pid): _on_buy_stamina(pid))
		_item_list.add_child(card)

func _build_chapter_tab() -> void:
	for p in _products.get("chapter_products", []):
		var ch = p["chapter"]
		var cost = p["cost_currency"]
		var is_unlocked = SaveManager.is_chapter_unlocked(ch)
		var check = ChapterUnlockScript.can_unlock(ch)
		var card = _make_card()
		if is_unlocked:
			card.setup(p["id"], "📖", "챕터 %d" % ch, "해금됨", false)
		else:
			var can_buy = check["can_unlock"]
			var reason = "" if can_buy else check.get("reason", "")
			var price_text = "💰 %d" % cost if can_buy else "💰 %d  (%s)" % [cost, reason]
			card.setup(p["id"], "📖", "챕터 %d 해금" % ch, price_text, can_buy)
			card.purchase_requested.connect(func(pid): _on_buy_chapter(pid))
		_item_list.add_child(card)

func _on_buy_currency(product_id: String) -> void:
	var result = ShopManager.buy_currency(product_id)
	_show_result_msg(result)
	if result["success"]:
		_animate_currency_gain(result["amount"])
	_refresh()

func _on_buy_stamina(product_id: String) -> void:
	var result = ShopManager.buy_stamina(product_id)
	_show_result_msg(result)
	if result["success"]:
		_animate_stamina_gain(result["amount"])
	_refresh()

func _on_buy_chapter(product_id: String) -> void:
	# product_id 형식: "chapter_N"
	var parts = product_id.split("_")
	var ch = int(parts[1]) if parts.size() >= 2 else 0
	var result = ShopManager.buy_chapter_unlock(ch)
	_show_result_msg(result)
	_refresh()

func _show_result_msg(result: Dictionary) -> void:
	if result["success"]:
		_msg_label.text = "구매 완료!"
		_msg_label.modulate = Color.GREEN
	else:
		_msg_label.text = result.get("reason", "구매 실패")
		_msg_label.modulate = Color.RED
	_msg_label.visible = true
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func(): _msg_label.visible = false)

func _animate_currency_gain(amount: int) -> void:
	var tween = create_tween()
	var start_val = SaveManager.get_currency() - amount
	tween.tween_method(func(v: int): _currency_label.text = "💰 %d" % v, start_val, SaveManager.get_currency(), 1.0)

func _animate_stamina_gain(_amount: int) -> void:
	var tween = create_tween()
	tween.tween_method(
		func(v: int): _stamina_label.text = "⚡ %d/%d" % [v, StaminaManager.max_stamina],
		StaminaManager.current_stamina - _amount,
		StaminaManager.current_stamina,
		1.0
	)

func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/main/stage_select.tscn")

func _make_card() -> ShopItemCard:
	return load(ITEM_CARD_SCENE).instantiate() as ShopItemCard
