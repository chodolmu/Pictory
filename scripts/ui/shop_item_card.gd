class_name ShopItemCard
extends PanelContainer

signal purchase_requested(product_id: String)

@onready var _icon_label: Label = $HBox/IconLabel
@onready var _name_label: Label = $HBox/VBox/NameLabel
@onready var _price_label: Label = $HBox/VBox/PriceLabel
@onready var _buy_btn: Button = $HBox/BuyButton
@onready var _badge_label: Label = $HBox/BadgeLabel

var _product_id: String = ""

func setup(product_id: String, icon: String, name_text: String, price_text: String, can_buy: bool, badge: String = "") -> void:
	_product_id = product_id
	_icon_label.text = icon
	_name_label.text = name_text
	_price_label.text = price_text
	_buy_btn.disabled = not can_buy
	if badge.is_empty():
		_badge_label.visible = false
	else:
		_badge_label.visible = true
		_badge_label.text = badge
	_buy_btn.pressed.connect(func(): purchase_requested.emit(_product_id))

func set_can_buy(value: bool) -> void:
	_buy_btn.disabled = not value
