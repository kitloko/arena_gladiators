class_name ItemDropPanel
extends PanelContainer

## Painel que serve de origem e/ou destino de arrastar-e-soltar de item.
##
## Não conhece NENHUMA regra de jogo: quem decide se o drop vale e o que fazer
## com ele é a tela, pelos callbacks `on_item_dropped` (recebe o dado arrastado e
## o slot do alvo) e `on_message` (texto para a barra de recado).
##
## Uso na tela:
##   var painel := ItemDropPanel.new()
##   painel.accepts_item_kind = "bag_item"      # só aceita item vindo da bolsa
##   painel.accepts_slot = "weapon"            # só no slot da arma
##   painel.drag_payload = {"kind": "equipped_item", "slot": "weapon", ...}
##   painel.on_item_dropped = Callable(self, "_handle_drop")

## Tipo de dado que este painel aceita no drop ("" = qualquer): "bag_item" (item
## da bolsa, para equipar) ou "equipped_item" (item equipado, para devolver à bolsa).
var accepts_item_kind: String = ""
## Slot do corpo que este painel aceita ("" = qualquer, caso da bolsa).
var accepts_slot: String = ""
## Dicionário entregue ao arrastar este painel ({} = o painel não é arrastável).
var drag_payload: Dictionary = {}
var on_item_dropped: Callable = Callable()
var on_message: Callable = Callable()
## Id do item equipado neste slot (a tela preenche): um painel não aceita o item
## que já está nele.
var equipped_id_hint: String = ""
## Rótulo de vazio ("— vazio —"), escondido enquanto o painel é um alvo válido.
var empty_hint: Control = null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_payload.is_empty():
		return null
	var preview := Label.new()
	preview.text = str(drag_payload.get("name", "item"))
	preview.add_theme_font_size_override("font_size", 15)
	preview.add_theme_color_override("font_color", Color("f7edf4"))
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("272033")
	style.border_color = Color("f5c451")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", style)
	box.add_child(preview)
	set_drag_preview(box)
	return drag_payload

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if on_item_dropped.is_null() or not (data is Dictionary):
		return false
	var payload := data as Dictionary
	if accepts_item_kind != "" and str(payload.get("kind", "")) != accepts_item_kind:
		return false
	if accepts_slot != "" and str(payload.get("slot", "")) != accepts_slot:
		return false
	# Item que já está neste slot não é drop válido (arrastar do slot para si mesmo).
	if str(payload.get("id", "")) != "" and str(payload.get("id", "")) == str(equipped_id_hint):
		return false
	_set_highlight(true)
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_set_highlight(false)
	on_item_dropped.call(data, accepts_slot)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_set_highlight(false)

func _set_highlight(active: bool) -> void:
	modulate = Color(1.25, 1.25, 1.25) if active else Color.WHITE
	if empty_hint != null:
		empty_hint.visible = not active

func _say(text_value: String) -> void:
	if not on_message.is_null():
		on_message.call(text_value)
