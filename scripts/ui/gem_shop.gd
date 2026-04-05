class_name GemShop
extends Control

## 젬 상점 — 실결제로 젬 구매 (Phase 2에서는 stub 즉시 지급).

const PRODUCTS_PATH = "res://resources/shop/gem_products.json"

@onready var _balance_label: Label = $MarginContainer/VBox/Header/BalanceLabel
@onready var _product_list: VBoxContainer = $MarginContainer/VBox/ScrollContainer/ProductList
@onready var _back_btn: Button = $MarginContainer/VBox/Header/BackButton

var _products: Array = []

func _ready() -> void:
	_back_btn.pressed.connect(_on_back)
	GemManager.gems_changed.connect(_on_gems_changed)
	_load_products()
	_update_balance()
	_build_product_list()

func _load_products() -> void:
	_products = [
		{"id": "gem_100", "gems": 100, "price_krw": 1200},
		{"id": "gem_500", "gems": 500, "price_krw": 5900},
		{"id": "gem_1200", "gems": 1200, "price_krw": 11000},
		{"id": "gem_3000", "gems": 3000, "price_krw": 25000},
	]
	# JSON 파일이 있으면 로드
	if FileAccess.file_exists(PRODUCTS_PATH):
		var file = FileAccess.open(PRODUCTS_PATH, FileAccess.READ)
		var parsed = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Array:
			_products = parsed

func _update_balance() -> void:
	_balance_label.text = "💎 %d" % GemManager.get_balance()

func _on_gems_changed(_current: int) -> void:
	_update_balance()

func _build_product_list() -> void:
	for child in _product_list.get_children():
		child.queue_free()

	for product in _products:
		var card = _create_product_card(product)
		_product_list.add_child(card)

func _create_product_card(product: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 60)

	var gem_label = Label.new()
	gem_label.text = "💎 %d개" % product.get("gems", 0)
	gem_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gem_label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(gem_label)

	var buy_btn = Button.new()
	buy_btn.text = "₩%s" % _format_price(product.get("price_krw", 0))
	buy_btn.custom_minimum_size = Vector2(100, 48)
	buy_btn.pressed.connect(_on_purchase.bind(product))
	hbox.add_child(buy_btn)

	return hbox

func _on_purchase(product: Dictionary) -> void:
	# TODO: 실제 IAP 연동. 현재는 stub 즉시 지급.
	var gems = product.get("gems", 0)
	GemManager.add(gems)
	print("Gem purchase (stub): +%d gems" % gems)

func _format_price(price: int) -> String:
	var s = str(price)
	var result = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result

func _on_back() -> void:
	SceneManager.change_scene("res://scenes/main/main_menu.tscn")
