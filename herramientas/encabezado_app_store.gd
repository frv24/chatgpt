extends SceneTree
## Crea el «encabezado» de la página del App Store (3840 x 1646): fondo rosa, papel
## picado, el nombre del juego y un abanico de fichas. Se ejecuta con pantalla:
##   godot --script res://herramientas/encabezado_app_store.gd
## Resultado: tienda/encabezado_app_store_3840x1646.png (sin transparencia).

const ROSA := Color("c2185b")
const CREMA := Color("fbf3e4")
const ANCHO := 3840
const ALTO := 1646
const FICHAS := ["bam2", "car5", "dR", "comodin", "dV", "cir8", "flor"]


func _initialize() -> void:
	_crear()


func _crear() -> void:
	var vista := SubViewport.new()
	vista.size = Vector2i(ANCHO, ALTO)
	vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vista)

	var fondo := ColorRect.new()
	fondo.color = ROSA
	fondo.size = Vector2(ANCHO, ALTO)
	vista.add_child(fondo)

	var escala := 2.6
	var picado := PapelPicado.new()
	picado.color_fondo = ROSA
	picado.colores = PapelPicado.COLORES.filter(func(c): return c != ROSA) + [CREMA]
	picado.size = Vector2(ANCHO / escala, 58)
	picado.scale = Vector2(escala, escala)
	picado.position = Vector2(0, -10)
	vista.add_child(picado)

	# Texto a la izquierda (dentro de la zona central, por si Apple recorta los lados).
	var titulo := Label.new()
	titulo.text = "Mahjong\nen Español"
	titulo.add_theme_font_size_override("font_size", 250)
	titulo.add_theme_color_override("font_color", CREMA)
	titulo.add_theme_constant_override("line_spacing", -30)
	titulo.position = Vector2(560, 470)
	vista.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = "Aprende y juega"
	subtitulo.add_theme_font_size_override("font_size", 120)
	subtitulo.add_theme_color_override("font_color", Color("f8bbd0"))
	subtitulo.position = Vector2(570, 1150)
	vista.add_child(subtitulo)

	# Abanico de fichas a la derecha.
	var radio := 1100.0
	var centro := Vector2(2880, 430 + 352 * 1.3 + radio)
	for i in FICHAS.size():
		var textura: Texture2D = load("res://assets/fichas/%s.png" % FICHAS[i])
		var tam := textura.get_size() * 1.3
		var angulo := deg_to_rad(-30 + i * 10)
		var ficha := TextureRect.new()
		ficha.texture = textura
		ficha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ficha.size = tam
		ficha.pivot_offset = Vector2(tam.x / 2, tam.y + radio)
		ficha.position = centro - ficha.pivot_offset
		ficha.rotation = angulo
		vista.add_child(ficha)

	for i in 4:
		await process_frame
	var imagen := vista.get_texture().get_image()
	imagen.convert(Image.FORMAT_RGB8)
	imagen.save_png(ProjectSettings.globalize_path("res://tienda/encabezado_app_store_3840x1646.png"))
	print("Encabezado listo.")
	quit()
