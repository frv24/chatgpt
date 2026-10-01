extends SceneTree
## Genera el ícono redondeado y la pantalla de carga en alta resolución.
## Se ejecuta (con pantalla, no en modo headless) así:
##   godot --script res://herramientas/generar_imagenes.gd
##
## - assets/icono/icono_192.png        ícono clásico con las esquinas redondeadas
## - assets/icono/icono_redondo_512.png ícono redondeado (ventana del juego)
## - assets/icono/pantalla_carga.png    pantalla de carga de 2560 x 1440 (nítida en
##                                      cualquier teléfono)
## assets/icono/icono_512.png se deja CUADRADO: es el que pide Google Play, que redondea
## las esquinas por su cuenta.

const ROSA := Color("c2185b")
const CREMA := Color("fbf3e4")
const ANCHO := 2560
const ALTO := 1440


func _initialize() -> void:
	_iconos_redondeados()
	_pantalla_de_carga()


func _ruta(archivo: String) -> String:
	return ProjectSettings.globalize_path("res://assets/icono/" + archivo)


## Esquinas redondeadas (con borde suave) como las de los íconos de Android.
func _redondear(imagen: Image, radio_relativo: float) -> Image:
	var r := imagen.get_width() * radio_relativo
	var w := imagen.get_width()
	var h := imagen.get_height()
	imagen.convert(Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var cx := clampf(x + 0.5, r, w - r)
			var cy := clampf(y + 0.5, r, h - r)
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			var alfa := clampf(r - d + 0.5, 0.0, 1.0)
			if alfa < 1.0:
				var c := imagen.get_pixel(x, y)
				c.a *= alfa
				imagen.set_pixel(x, y, c)
	return imagen


func _iconos_redondeados() -> void:
	var original := Image.load_from_file(_ruta("icono_512.png"))
	var grande := original.duplicate() as Image
	_redondear(grande, 0.22).save_png(_ruta("icono_redondo_512.png"))
	var pequeno := original.duplicate() as Image
	pequeno.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	_redondear(pequeno, 0.22).save_png(_ruta("icono_192.png"))
	print("Íconos redondeados listos.")


func _pantalla_de_carga() -> void:
	var vista := SubViewport.new()
	vista.size = Vector2i(ANCHO, ALTO)
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vista)

	var fondo := ColorRect.new()
	fondo.color = ROSA
	fondo.size = Vector2(ANCHO, ALTO)
	vista.add_child(fondo)

	# Papel picado: una tira centrada, a doble tamaño (sin el rosa del fondo).
	var picado := PapelPicado.new()
	picado.color_fondo = ROSA
	picado.colores = PapelPicado.COLORES.filter(func(c): return c != ROSA) + [CREMA]
	var banderas := 13
	var ancho_tira := banderas * (PapelPicado.ANCHO_BANDERA + PapelPicado.SEPARACION)
	picado.size = Vector2(ancho_tira - 1, 58)  # justo `banderas` banderas
	picado.scale = Vector2(2, 2)
	picado.position = Vector2((ANCHO - ancho_tira * 2) / 2, 60)
	vista.add_child(picado)

	# El comodín (tu diseño) con su sombra.
	var textura: Texture2D = load("res://assets/fichas/comodin.png")
	var tam := textura.get_size() * 1.25
	var pos := Vector2((ANCHO - tam.x) / 2, 300)
	var sombra := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.28)
	estilo.set_corner_radius_all(28)
	sombra.add_theme_stylebox_override("panel", estilo)
	sombra.position = pos + Vector2(16, 18)
	sombra.size = tam
	vista.add_child(sombra)
	var comodin := TextureRect.new()
	comodin.texture = textura
	comodin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	comodin.position = pos
	comodin.size = tam
	vista.add_child(comodin)

	var titulo := _texto("Mahjong en Español", 170, CREMA)
	titulo.position.y = pos.y + tam.y + 50
	vista.add_child(titulo)
	var subtitulo := _texto("Aprende y juega", 84, Color("f8bbd0"))
	subtitulo.position.y = titulo.position.y + 230
	vista.add_child(subtitulo)

	for i in 4:
		await process_frame
	vista.get_texture().get_image().save_png(_ruta("pantalla_carga.png"))
	print("Pantalla de carga lista.")
	quit()


func _texto(texto: String, tam: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.size.x = ANCHO
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta
