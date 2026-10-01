class_name Mesa
extends Control
## La mesa vista desde arriba, como si estuvieras sentado en ella:
##   tú abajo, el jugador de tu DERECHA a la derecha, el de ENFRENTE arriba
##   y el de tu IZQUIERDA a la izquierda.
## Cada jugador tiene su atril con sus fichas boca abajo y su viento (Este, Sur, Oeste, Norte).
## Durante el Charleston, unas flechas enseñan hacia dónde van las fichas (la tuya en
## amarillo) y, al pasar, las fichas se mueven por la mesa. Al jugar, brilla quien tiene
## el turno y en el centro se ve la última ficha descartada (con una línea hacia quien la
## tiró) y cuántas fichas quedan en el muro.

## Todo se dibuja en un cuadrado de este tamaño y luego se ajusta al espacio disponible.
const LADO := 250.0
const AMARILLO := Color("ffe082")
const ROSA := Color("f48fb1")
## Hacia dónde está cada asiento visto desde el centro: 0 = tú (abajo), 1 = derecha,
## 2 = enfrente (arriba), 3 = izquierda.
const DIRECCIONES := [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]

var partida: Partida
## Dirección del pase del Charleston (Charleston.DERECHA, ENFRENTE o IZQUIERDA); 0 = sin flechas.
var direccion_pase := 0
## Si es true, se resalta al jugador que tiene el turno.
var mostrar_turno := false

var _avance_pase := -1.0  # animación de un pase: de 0 a 1 (-1 = no hay animación)
var _direccion_animada := 0
var _brillo := 0.0  # pulso de las flechas
var _reverso: Texture2D
## La última ficha descartada (se dibuja en el centro) y quién la tiró.
var _descarte: Ficha = null
var _quien_descarto := -1
var _escala_descarte := 1.0


func _init() -> void:
	custom_minimum_size = Vector2(300, 0)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reverso = FichaVisual.diseno_de("reverso")


func _ready() -> void:
	var pulso := create_tween().set_loops()
	pulso.tween_method(_poner_brillo, 0.0, 1.0, 0.6)
	pulso.tween_method(_poner_brillo, 1.0, 0.0, 0.6)


func actualizar(p: Partida, direccion: int, turno: bool) -> void:
	partida = p
	direccion_pase = direccion
	mostrar_turno = turno
	var ultimo: Dictionary = p.descartes.back() if turno and not p.descartes.is_empty() else {}
	var ficha: Ficha = ultimo.get("ficha")
	if ficha != _descarte:
		_descarte = ficha
		_quien_descarto = ultimo.get("jugador", -1)
		if ficha:
			# La ficha nueva aparece con un pequeño salto.
			var tween := create_tween()
			tween.tween_method(_poner_escala_descarte, 0.4, 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _poner_escala_descarte(valor: float) -> void:
	_escala_descarte = valor
	queue_redraw()


## Las fichas de todos viajan a la vez hacia su destino.
func animar_pase(direccion: int) -> void:
	_direccion_animada = direccion
	var tween := create_tween()
	tween.tween_method(_poner_avance, 0.0, 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): _poner_avance(-1.0))


func _poner_brillo(valor: float) -> void:
	_brillo = valor
	if direccion_pase != 0:
		queue_redraw()


func _poner_avance(valor: float) -> void:
	_avance_pase = valor
	queue_redraw()


func _draw() -> void:
	if partida == null:
		return
	# Todo se dibuja en un cuadrado de LADO x LADO, centrado y a escala.
	var escala := minf(size.x, size.y) / LADO
	var origen := (size - Vector2(LADO, LADO) * escala) / 2
	draw_set_transform(origen, 0.0, Vector2(escala, escala))

	var c := Vector2(LADO, LADO) / 2
	# El tapete.
	var tapete := StyleBoxFlat.new()
	tapete.bg_color = Color("146b45")
	tapete.border_color = Color("0b3d27")
	tapete.set_border_width_all(4)
	tapete.set_corner_radius_all(18)
	draw_style_box(tapete, Rect2(Vector2(30, 30), Vector2(LADO - 60, LADO - 60)))

	for j in 4:
		_dibujar_asiento(j, c)

	if direccion_pase != 0 and _avance_pase < 0:
		for j in 4:
			_dibujar_flecha(j, (j + direccion_pase) % 4, c, j == 0)
	if _avance_pase >= 0:
		for j in 4:
			_dibujar_fichas_en_camino(j, (j + _direccion_animada) % 4, c)
	elif direccion_pase == 0:
		var fuente := get_theme_default_font()
		if _descarte:
			_dibujar_descarte(c, fuente)
		else:
			_texto(fuente, "Muro", c + Vector2(0, -4), 14, Color(1, 1, 1, 0.7))
			_texto(fuente, str(partida.mazo.quedan()), c + Vector2(0, 18), 22, Color.WHITE)


## La última ficha descartada en el centro, con una línea hacia quien la tiró.
func _dibujar_descarte(c: Vector2, fuente: Font) -> void:
	var tam := Vector2(46, 63) * _escala_descarte
	var rect := Rect2(c + Vector2(0, -6) - tam / 2, tam)
	if _quien_descarto >= 0:
		var desde: Vector2 = c + DIRECCIONES[_quien_descarto] * 62
		var hasta: Vector2 = rect.get_center() + DIRECCIONES[_quien_descarto] * 30
		draw_line(desde, hasta, Color(AMARILLO, 0.6), 3.0, true)
		draw_circle(desde, 4, Color(AMARILLO, 0.8))
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("fbf6e9")
	fondo.border_color = AMARILLO
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(5)
	draw_style_box(fondo, rect)
	var diseno := FichaVisual.diseno_de(_descarte.clave())
	if diseno:
		draw_texture_rect(diseno, rect.grow(-2), false)
	else:
		_texto(fuente, _descarte.nombre(), rect.get_center(), 10, Color("3b2a1a"))
	_texto(fuente, _descarte.nombre(), c + Vector2(0, 40), 13, Color.WHITE)
	_texto(fuente, "Muro: %d" % partida.mazo.quedan(), c + Vector2(0, 55), 11, Color(1, 1, 1, 0.65))


## El atril de un jugador (sus fichas boca abajo) y su nombre con su viento.
func _dibujar_asiento(j: int, c: Vector2) -> void:
	var v: Vector2 = DIRECCIONES[j]
	var horizontal := v.x == 0
	var cuantas: int = partida.manos[j].size()
	var largo_ficha := 11.0
	var ancho_ficha := 16.0
	var largo := largo_ficha * cuantas
	var centro_atril := c + v * (LADO / 2 - 11)

	# Quien tiene el turno brilla en amarillo.
	if mostrar_turno and partida.turno == j and not partida.terminada:
		var marco := Rect2(centro_atril - (Vector2(largo, ancho_ficha) if horizontal else Vector2(ancho_ficha, largo)) / 2,
			Vector2(largo, ancho_ficha) if horizontal else Vector2(ancho_ficha, largo)).grow(5)
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color(AMARILLO, 0.35)
		estilo.border_color = AMARILLO
		estilo.set_border_width_all(2)
		estilo.set_corner_radius_all(6)
		draw_style_box(estilo, marco)

	for i in cuantas:
		var desplazamiento := (i - (cuantas - 1) / 2.0) * largo_ficha
		var centro := centro_atril + (Vector2(desplazamiento, 0) if horizontal else Vector2(0, desplazamiento))
		var tam := Vector2(largo_ficha - 1, ancho_ficha) if horizontal else Vector2(ancho_ficha, largo_ficha - 1)
		var rect := Rect2(centro - tam / 2, tam)
		if j == 0:
			# Tus fichas, de cara (color marfil).
			draw_rect(rect, Color("fbf6e9"))
			draw_rect(rect, Color("9e9480"), false, 1.0)
		elif _reverso:
			draw_texture_rect(_reverso, rect, false, Color.WHITE, not horizontal)
		else:
			draw_rect(rect, Color("1f4e8c"))

	# Nombre y viento, dentro del tapete junto al atril.
	var fuente := get_theme_default_font()
	var nombre: String = Partida.NOMBRES[j]
	var viento := partida.viento(j)
	var color_nombre := ROSA if j == 0 else Color.WHITE
	var color_viento := AMARILLO if viento == "Este" else Color("b9f6ca")
	if horizontal:
		# Arriba y abajo: en una línea, «Tú · Este».
		var pos := c + v * 86
		_texto_doble(fuente, nombre + " · ", viento, pos, 15, color_nombre, color_viento)
	else:
		# A los lados: dos líneas, por encima de las flechas.
		var pos := c + Vector2(v.x * 66, -34)
		_texto(fuente, nombre, pos, 14, color_nombre)
		_texto(fuente, viento, pos + Vector2(0, 16), 14, color_viento)


## Flecha del pase de `desde` a `hasta`. La tuya se ve gruesa y en amarillo.
func _dibujar_flecha(desde: int, hasta: int, c: Vector2, mia: bool) -> void:
	var inicio: Vector2 = c + DIRECCIONES[desde] * 50
	var fin: Vector2 = c + DIRECCIONES[hasta] * 50
	var direccion := (fin - inicio).normalized()
	# Las flechas que van en sentidos contrarios (enfrente) se separan un poco.
	var lado := Vector2(-direccion.y, direccion.x) * 9
	inicio += lado + direccion * 4
	fin += lado - direccion * 4
	var color := AMARILLO.lerp(Color.WHITE, _brillo * 0.5) if mia else Color(1, 1, 1, 0.3)
	var grosor := 5.0 if mia else 2.0
	var punta := 14.0 if mia else 9.0
	draw_line(inicio, fin - direccion * punta * 0.6, color, grosor, true)
	var perpendicular := Vector2(-direccion.y, direccion.x)
	draw_colored_polygon(PackedVector2Array([
		fin,
		fin - direccion * punta + perpendicular * punta * 0.6,
		fin - direccion * punta - perpendicular * punta * 0.6,
	]), color)


## Durante la animación del pase: 3 fichas de cada jugador camino de su destino.
func _dibujar_fichas_en_camino(desde: int, hasta: int, c: Vector2) -> void:
	var inicio: Vector2 = c + DIRECCIONES[desde] * (LADO / 2 - 14)
	var fin: Vector2 = c + DIRECCIONES[hasta] * (LADO / 2 - 14)
	var pos := inicio.lerp(fin, _avance_pase)
	var direccion := (fin - inicio).normalized()
	var lado := Vector2(-direccion.y, direccion.x)
	for k in 3:
		var centro := pos + lado * (k - 1) * 13
		var rect := Rect2(centro - Vector2(6, 8), Vector2(12, 16))
		if desde == 0 or _reverso == null:
			draw_rect(rect, Color("fbf6e9") if desde == 0 else Color("1f4e8c"))
			draw_rect(rect, AMARILLO if desde == 0 else Color.BLACK, false, 1.5)
		else:
			draw_texture_rect(_reverso, rect, false)


func _texto(fuente: Font, texto: String, centro: Vector2, tam: int, color: Color) -> void:
	var ancho := fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	draw_string_outline(fuente, centro + Vector2(-ancho / 2, tam * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 3, Color(0, 0, 0, 0.5))
	draw_string(fuente, centro + Vector2(-ancho / 2, tam * 0.35), texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, color)


## Dos textos seguidos de distinto color, centrados juntos.
func _texto_doble(fuente: Font, a: String, b: String, centro: Vector2, tam: int, color_a: Color, color_b: Color) -> void:
	var ancho_a := fuente.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var ancho_b := fuente.get_string_size(b, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	var x := centro.x - (ancho_a + ancho_b) / 2
	_texto(fuente, a, Vector2(x + ancho_a / 2, centro.y), tam, color_a)
	_texto(fuente, b, Vector2(x + ancho_a + ancho_b / 2, centro.y), tam, color_b)
