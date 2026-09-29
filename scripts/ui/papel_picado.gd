class_name PapelPicado
extends Control
## Una tira de papel picado (banderitas de colores con recortes) dibujada con código.
## Se usa como adorno en la parte de arriba de la tarjeta.

const COLORES := [Color("c2185b"), Color("1f6b3f"), Color("e0a100"), Color("1f4e8c"),
	Color("b5441f"), Color("6a3d9a")]
const ANCHO_BANDERA := 64.0
const SEPARACION := 8.0
## Color del fondo, para dibujar los recortes de las banderas.
var color_fondo := Color("fbf3e4")


func _init() -> void:
	custom_minimum_size.y = 58
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# El hilo del que cuelgan las banderas.
	draw_line(Vector2(0, 5), Vector2(size.x, 5), Color("7a5c3e"), 2.0)
	var cuantas := int(size.x / (ANCHO_BANDERA + SEPARACION)) + 1
	for i in cuantas:
		var x := i * (ANCHO_BANDERA + SEPARACION) + SEPARACION / 2
		_bandera(Rect2(x, 5, ANCHO_BANDERA, 48), COLORES[i % COLORES.size()])


func _bandera(r: Rect2, color: Color) -> void:
	# Cuerpo de la bandera con el borde de abajo en zigzag.
	var puntos := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y)])
	var picos := 6
	for p in range(picos, -1, -1):
		var x := r.position.x + r.size.x * p / picos
		var y := r.end.y if p % 2 == 0 else r.end.y - 8
		puntos.append(Vector2(x, y))
	draw_colored_polygon(puntos, color)
	# Recortes: un rombo en el centro y cuatro puntitos alrededor.
	var c := r.get_center() - Vector2(0, 4)
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9), c + Vector2(9, 0),
		c + Vector2(0, 9), c + Vector2(-9, 0)]), color_fondo)
	for d in [Vector2(-18, -10), Vector2(18, -10), Vector2(-18, 10), Vector2(18, 10)]:
		draw_circle(c + d, 3.0, color_fondo)
