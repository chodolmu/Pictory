class_name ShopManager
extends RefCounted
## 상점 구매 처리 유틸리티 (static 함수).
## IAP는 스텁으로 즉시 재화 지급.

const PRODUCTS_PATH := "res://resources/shop/products.json"
const ChapterUnlockScript = preload("res://scripts/data/chapter_unlock.gd")

static func get_products() -> Dictionary:
	var file = FileAccess.open(PRODUCTS_PATH, FileAccess.READ)
	if not file:
		push_error("ShopManager: products.json 로드 실패")
		return {}
	var text = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

## 행동력 구매 (재화 소모)
static func buy_stamina(product_id: String) -> Dictionary:
	var products = get_products()
	for p in products.get("stamina_products", []):
		if p["id"] == product_id:
			var cost = p["cost_currency"]
			if SaveManager.get_currency() < cost:
				return {"success": false, "reason": "재화가 부족합니다"}
			SaveManager.spend_currency(cost)
			StaminaManager.add(p["amount"])
			_record_purchase(product_id)
			return {"success": true, "amount": p["amount"]}
	return {"success": false, "reason": "상품을 찾을 수 없습니다"}

## 재화 구매 (IAP 스텁 — 즉시 지급)
static func buy_currency(product_id: String) -> Dictionary:
	var products = get_products()
	for p in products.get("currency_products", []):
		if p["id"] == product_id:
			print("[ShopManager-IAP-STUB] 재화 구매: %s → +%d" % [product_id, p["amount"]])
			SaveManager.add_currency(p["amount"])
			_record_purchase(product_id)
			return {"success": true, "amount": p["amount"]}
	return {"success": false, "reason": "상품을 찾을 수 없습니다"}

## 챕터 해금 구매
static func buy_chapter_unlock(chapter: int) -> Dictionary:
	var result = ChapterUnlockScript.can_unlock(chapter)
	if not result["can_unlock"]:
		return {"success": false, "reason": result["reason"]}
	var ok = ChapterUnlockScript.try_unlock(chapter)
	if ok:
		_record_purchase("chapter_%d" % chapter)
		return {"success": true}
	return {"success": false, "reason": "해금 실패"}

static func _record_purchase(product_id: String) -> void:
	var history = SaveManager.get_shop_history()
	if not history.has(product_id):
		history[product_id] = {"count": 0, "last_date": ""}
	history[product_id]["count"] += 1
	history[product_id]["last_date"] = Time.get_date_string_from_system()
	SaveManager.save_shop_history(history)
