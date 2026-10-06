class_name FightEffects
extends RefCounted

## Efeitos e projéteis PROCEDURAIS da luta (etapa 8 do PLANO_3.0).
##
## Tudo é desenhado por CÓDIGO (Line2D/Polygon2D + Tween): nenhuma folha, nenhum
## asset externo. As funções são "dispara e esquece": criam o nó já ligado à
## árvore, animam e se autodestroem. NÃO usam await e não bloqueiam a luta — então
## o ritmo e o número de ações continuam idênticos (o balanceamento não sente).
##
## Onde cada coisa aparece:
##   - `slice_arc`   golpe corpo a corpo (arco de corte branco/dourado);
##   - `spark_ring`  aparo/defesa (faísca + anel curto);
##   - `hit_spray`   dano levado (respingo curto);
##   - `dust_puff`   recuo/avanço (poeira nos pés);
##   - `projectile`  ações à distância (flecha/virote/faca voando com rotação e rastro).

const SLASH := Color("fff6d5")
const SLASH_GOLD := Color("f5c451")
const SPARK := Color("bfe3ff")
const BLOOD := Color("d95858")
const BLOOD_LIGHT := Color("ff8a6b")
const DUST := Color(0.79, 0.7, 0.54, 0.55)

## Golpe corpo a corpo: um arco de corte que VARRE e some em ~0,28s.
static func slice_arc(parent: Node, from: Vector2, to: Vector2, duration: float = 0.28) -> Node2D:
	if parent == null:
		return null
	var node := Node2D.new()
	node.position = from
	node.z_index = 40
	node.modulate.a = 0.0
	var dir := to - from
	var angle := dir.angle() if dir.length() > 0.01 else 0.0
	var reach := clampf(from.distance_to(to), 60.0, 135.0)
	var outer := Line2D.new()
	outer.width = 7.0
	outer.default_color = SLASH
	var inner := Line2D.new()
	inner.width = 3.5
	inner.default_color = SLASH_GOLD
	var po := PackedVector2Array()
	var pi := PackedVector2Array()
	for i in 15:
		var t := float(i) / 14.0
		var a := lerpf(-0.85, 0.85, t)
		var r := reach * (0.42 + 0.58 * sin(PI * t))
		po.append(Vector2(cos(a) * r, sin(a) * r))
		pi.append(Vector2(cos(a) * (r * 0.84), sin(a) * (r * 0.84)))
	outer.points = po
	inner.points = pi
	node.add_child(outer)
	node.add_child(inner)
	node.rotation = angle - 0.35
	node.scale = Vector2(0.72, 0.72)
	parent.add_child(node)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2(1.06, 1.06), duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "rotation", angle + 0.22, duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.18)
	tw.set_parallel(false)
	tw.tween_property(node, "modulate:a", 0.0, duration * 0.7)
	tw.tween_callback(node.queue_free)
	return node

## Aparo/defesa: uma faísca (anel + raios curtos) que abre e some em ~0,28s.
static func spark_ring(parent: Node, at: Vector2, duration: float = 0.28) -> Node2D:
	if parent == null:
		return null
	var node := Node2D.new()
	node.position = at
	node.z_index = 41
	node.modulate.a = 0.0
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = SPARK
	var pts := PackedVector2Array()
	for i in 17:
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * 10.0, sin(a) * 10.0))
	ring.points = pts
	node.add_child(ring)
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.4
		var ray := Line2D.new()
		ray.width = 2.0
		ray.default_color = SPARK
		ray.points = PackedVector2Array([
			Vector2(cos(a) * 6.0, sin(a) * 6.0),
			Vector2(cos(a) * 18.0, sin(a) * 18.0),
		])
		node.add_child(ray)
	node.scale = Vector2(0.4, 0.4)
	parent.add_child(node)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2(1.35, 1.35), duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.14)
	tw.set_parallel(false)
	tw.tween_property(node, "modulate:a", 0.0, duration * 0.6)
	tw.tween_callback(node.queue_free)
	return node

## Dano levado: um respingo curto de linhas de sangue no sentido do golpe.
static func hit_spray(parent: Node, at: Vector2, toward: Vector2, duration: float = 0.3) -> Node2D:
	if parent == null:
		return null
	var node := Node2D.new()
	node.position = at
	node.z_index = 42
	var base := toward.angle() if toward.length() > 0.01 else 0.0
	var spreads := [-0.9, -0.5, -0.2, 0.2, 0.5, 0.9]
	for i in spreads.size():
		var a := base + float(spreads[i])
		var ln := Line2D.new()
		ln.width = 2.5
		ln.default_color = BLOOD if i % 2 == 0 else BLOOD_LIGHT
		ln.points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(cos(a), sin(a)) * (14.0 + float(i % 3) * 6.0),
		])
		node.add_child(ln)
	node.scale = Vector2(0.5, 0.5)
	parent.add_child(node)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2(1.7, 1.7), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	tw.set_parallel(false)
	tw.tween_callback(node.queue_free)
	return node

## Recuo/avanço: um puff de poeira nos pés que sobe e some.
static func dust_puff(parent: Node, at: Vector2, duration: float = 0.5) -> Node2D:
	if parent == null:
		return null
	var node := Node2D.new()
	node.position = at
	node.z_index = 25
	var offsets := [Vector2(-14, 0), Vector2(0, -2), Vector2(14, 0), Vector2(-6, -8), Vector2(8, -8)]
	for i in offsets.size():
		var puff := Polygon2D.new()
		puff.color = DUST
		var r := 6.0 + float(i % 3) * 3.0
		var pts := PackedVector2Array()
		for k in 10:
			var a := TAU * float(k) / 10.0
			pts.append(Vector2(cos(a) * r, sin(a) * r * 0.7))
		puff.polygon = pts
		puff.position = offsets[i]
		node.add_child(puff)
	parent.add_child(node)
	var tw := parent.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "position", at + Vector2(0, -18), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.5, 1.5), duration)
	tw.tween_property(node, "modulate:a", 0.0, duration)
	tw.set_parallel(false)
	tw.tween_callback(node.queue_free)
	return node

## Ações à distância: um projétil (seta com haste, ponta e rastro leve) VOANDO do
## atacante até o alvo, com rotação no sentido do voo. `bands` é a distância
## lógica da luta (1..N): faixas maiores voam um pouco mais devagar. Ao chegar,
## solta uma faísca de impacto e some.
static func projectile(parent: Node, from: Vector2, to: Vector2, bands: int = 1, duration: float = 0.3) -> Node2D:
	if parent == null:
		return null
	var node := Node2D.new()
	node.position = from
	node.z_index = 45
	var dir := to - from
	node.rotation = dir.angle() if dir.length() > 0.01 else 0.0
	var shaft := Line2D.new()
	shaft.width = 3.0
	shaft.default_color = Color("efe3c2")
	shaft.points = PackedVector2Array([Vector2(-18, 0), Vector2(10, 0)])
	node.add_child(shaft)
	var head := Polygon2D.new()
	head.color = Color("d6dde8")
	head.polygon = PackedVector2Array([Vector2(18, 0), Vector2(7, -5), Vector2(7, 5)])
	node.add_child(head)
	var tail := Line2D.new()
	tail.width = 5.0
	tail.default_color = Color(0.98, 0.94, 0.78, 0.32)
	tail.points = PackedVector2Array([Vector2(-40, 0), Vector2(-16, 0)])
	node.add_child(tail)
	parent.add_child(node)
	var dur := clampf(duration + 0.045 * float(maxi(0, bands - 1)), 0.22, 0.6)
	var tw := parent.create_tween()
	tw.tween_property(node, "position", to, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		spark_ring(parent, to, 0.22)
		node.queue_free())
	return node
