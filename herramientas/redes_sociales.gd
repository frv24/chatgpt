extends SceneTree
## Crea las imágenes para redes sociales (Instagram, Facebook, TikTok, WhatsApp) con el
## estilo del juego: rosa mexicano, papel picado, tus fichas y fotos del juego.
## Antes hay que tomar las fotos del juego sin marco:
##   godot --script res://herramientas/capturas_tienda.gd -- ancho=2177 alto=1224 carpeta=marketing/_tmp crudas=marketing/_capturas
## Luego (con pantalla, no headless):
##   godot --script res://herramientas/redes_sociales.gd
## Resultado: marketing/redes/ (publicaciones 1080x1080, historias 1080x1920 y portada de Facebook).

const ROSA := Color("c2185b")
const MORADO := Color("4a2470")
const CREMA := Color("fbf3e4")
const ROSA_CLARO := Color("f8bbd0")
const AMARILLO := Color("ffe082")
const CARPETA := "res://marketing/redes/"
const CAPTURAS := "res://marketing/_capturas/"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARPETA))
	_todo()


func _todo() -> void:
	await _post_lanzamiento()
	await _post_fichas()
	await _post_captura("post_3_charleston", "¿Qué es el Charleston?", "3_charleston",
		"Antes de jugar, todos cambian 3 fichas: a la derecha, enfrente y a la izquierda. La app te enseña con flechas hacia dónde van.")
	await _post_comodin()
	await _post_captura("post_5_tarjeta", "Tu Tarjeta 2026, fácil de entender", "4_tarjeta",
		"Te muestra primero las manos que tienes más cerca, con tus fichas encendidas y las que te faltan apagadas.")
	await _post_muertos(Vector2i(1080, 1080), "post_6_dia_de_muertos")
	await _post_niveles()
	await _post_captura("post_8_tutorial", "Aprende jugando", "2_tutorial",
		"Un tutorial te guía paso a paso hasta tu primer ¡Mahjong! Sin saber nada antes.")
	await _historia_lanzamiento()
	await _historia_captura("historia_2_tutorial", "Aprende Mahjong\nen español", "2_tutorial",
		"Un tutorial te guía paso a paso.\nLuego juegas contra 3 rivales.")
	await _post_muertos(Vector2i(1080, 1920), "historia_3_dia_de_muertos")
	await _portada_facebook()
	print("Redes listas.")
	quit()


# --- Piezas ------------------------------------------------------------------

func _post_lanzamiento() -> void:
	var v := _lienzo(Vector2i(1080, 1080), ROSA)
	_texto(v, "¡YA DISPONIBLE!", 46, AMARILLO, 150, 1080)
	_texto(v, "Mahjong\nen Español", 132, CREMA, 220, 1080, -18)
	_texto(v, "Aprende Mahjong americano paso a paso", 40, ROSA_CLARO, 540, 1080)
	_abanico(v, ["bam2", "car5", "dR", "comodin", "dV", "cir8", "flor"], Vector2(540, 1580), 0.66, 700.0)
	_franja(v, "Gratis · iPhone · iPad · Android", 1080)
	await _guardar(v, "post_1_lanzamiento")


func _post_fichas() -> void:
	var v := _lienzo(Vector2i(1080, 1080), ROSA)
	_texto(v, "Conoce las fichas", 76, CREMA, 110, 1080)
	_texto(v, "Mahjong americano con diseño mexicano", 36, ROSA_CLARO, 210, 1080)
	var fichas := [["bam5", "Nopal"], ["car5", "Picado"], ["cir5", "Sol"], ["comodin", "Comodín"],
		["dR", "Chile"], ["dV", "Maguey"], ["dB", "Blanco"], ["flor", "Cempasúchil"]]
	for i in fichas.size():
		var x := 150 + (i % 4) * 260
		var y := 285 + (i / 4) * 340
		_ficha(v, fichas[i][0], Vector2(x, y + 125), 0.66)
		_texto(v, fichas[i][1], 34, CREMA, y + 250, 260, 0, x - 130)
	_franja(v, "Mahjong en Español · Aprende y juega", 1080)
	await _guardar(v, "post_2_fichas")


func _post_comodin() -> void:
	var v := _lienzo(Vector2i(1080, 1080), ROSA)
	_texto(v, "El comodín", 92, CREMA, 110, 1080)
	_ficha(v, "comodin", Vector2(540, 470), 1.35, -6.0)
	_texto(v, "Sustituye a cualquier ficha en grupos de 3 o más.\n¡Pero nunca se pasa en el Charleston!", 40,
		CREMA, 750, 940, 0, 70)
	_franja(v, "Mahjong en Español · Aprende y juega", 1080)
	await _guardar(v, "post_4_comodin")


func _post_niveles() -> void:
	var v := _lienzo(Vector2i(1080, 1080), ROSA)
	_texto(v, "4 niveles", 96, CREMA, 110, 1080)
	_texto(v, "Del primer día a la mesa real", 40, ROSA_CLARO, 235, 1080)
	var niveles := [["Fácil", "Todas las ayudas y rivales tranquilos"],
		["Normal", "Ayudas y rivales que juegan de verdad"],
		["Intermedio", "Consejos, sugerencias y marcador"],
		["Experto", "Sin ayudas, como en la mesa real"]]
	for i in niveles.size():
		var y := 330 + i * 150
		var caja := Panel.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = CREMA
		estilo.set_corner_radius_all(22)
		caja.add_theme_stylebox_override("panel", estilo)
		caja.position = Vector2(110, y)
		caja.size = Vector2(860, 125)
		v.add_child(caja)
		_texto(v, niveles[i][0], 44, ROSA, y + 12, 800, 0, 150, HORIZONTAL_ALIGNMENT_LEFT)
		_texto(v, niveles[i][1], 30, Color("3b2a1a"), y + 70, 800, 0, 150, HORIZONTAL_ALIGNMENT_LEFT)
	_franja(v, "Mahjong en Español · Aprende y juega", 1080)
	await _guardar(v, "post_7_niveles")


func _post_captura(nombre: String, titulo: String, captura: String, texto: String) -> void:
	var v := _lienzo(Vector2i(1080, 1080), ROSA)
	_texto(v, titulo, 64, CREMA, 105, 1080)
	_foto(v, captura, Rect2(60, 230, 960, 540))
	_texto(v, texto, 36, CREMA, 815, 960, 0, 60)
	_franja(v, "Mahjong en Español · Aprende y juega", 1080)
	await _guardar(v, nombre)


func _post_muertos(tam: Vector2i, nombre: String) -> void:
	var v := _lienzo(tam, MORADO)
	var alto := float(tam.y)
	# Flores de cempasúchil por todos lados.
	var semilla := RandomNumberGenerator.new()
	semilla.seed = 2026
	for i in 16:
		var p := Vector2(semilla.randf_range(40, tam.x - 40), semilla.randf_range(alto * 0.7, alto - 60))
		_ficha(v, "flor", p, semilla.randf_range(0.45, 0.7), semilla.randf_range(-25, 25))
	_texto(v, "Día de Muertos", 104, Color("ffb300"), alto * 0.12, tam.x)
	_texto(v, "Las flores de Mahjong en Español\nson de cempasúchil", 48, CREMA, alto * 0.12 + 150, tam.x)
	_texto(v, "Juega en familia y aprende\nMahjong americano en español", 40, Color("e1bee7"), alto * 0.12 + 320, tam.x)
	await _guardar(v, nombre)


func _historia_lanzamiento() -> void:
	var v := _lienzo(Vector2i(1080, 1920), ROSA)
	_texto(v, "¡YA DISPONIBLE!", 56, AMARILLO, 230, 1080)
	_texto(v, "Mahjong\nen Español", 150, CREMA, 320, 1080, -20)
	_texto(v, "Aprende Mahjong americano\npaso a paso, en español", 48, ROSA_CLARO, 720, 1080)
	_abanico(v, ["bam2", "car5", "dR", "comodin", "dV", "cir8", "flor"], Vector2(540, 2050), 0.8, 800.0)
	_texto(v, "Descárgalo gratis", 60, CREMA, 1700, 1080)
	_texto(v, "iPhone · iPad · Android", 40, ROSA_CLARO, 1785, 1080)
	await _guardar(v, "historia_1_lanzamiento")


func _historia_captura(nombre: String, titulo: String, captura: String, texto: String) -> void:
	var v := _lienzo(Vector2i(1080, 1920), ROSA)
	_texto(v, titulo, 96, CREMA, 260, 1080, -10)
	_foto(v, captura, Rect2(60, 640, 960, 540))
	_texto(v, texto, 48, CREMA, 1260, 960, 0, 60)
	_texto(v, "Mahjong en Español", 54, AMARILLO, 1640, 1080)
	_texto(v, "Gratis · iPhone · iPad · Android", 38, ROSA_CLARO, 1720, 1080)
	await _guardar(v, nombre)


func _portada_facebook() -> void:
	var v := _lienzo(Vector2i(1640, 624), ROSA, 1.1)
	_texto(v, "Mahjong en Español", 74, CREMA, 225, 800, 0, 110, HORIZONTAL_ALIGNMENT_LEFT)
	_texto(v, "Aprende y juega Mahjong americano", 34, ROSA_CLARO, 325, 800, 0, 114, HORIZONTAL_ALIGNMENT_LEFT)
	_abanico(v, ["bam2", "car5", "dR", "comodin", "dV", "cir8", "flor"], Vector2(1300, 880), 0.5, 520.0)
	await _guardar(v, "portada_facebook_1640x624")


# --- Ayudas para dibujar -----------------------------------------------------

## Fondo de color con papel picado arriba.
func _lienzo(tam: Vector2i, color: Color, escala_picado: float = 1.5) -> SubViewport:
	var v := SubViewport.new()
	v.size = tam
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(v)
	var fondo := ColorRect.new()
	fondo.color = color
	fondo.size = Vector2(tam)
	v.add_child(fondo)
	var picado := PapelPicado.new()
	picado.color_fondo = color
	picado.colores = PapelPicado.COLORES.filter(func(c): return c != color) + [CREMA]
	picado.size = Vector2(tam.x / escala_picado, 58)
	picado.scale = Vector2(escala_picado, escala_picado)
	picado.position = Vector2(0, -8)
	v.add_child(picado)
	return v


func _texto(v: SubViewport, texto: String, tam: int, color: Color, y: float, ancho: float,
		interlineado: int = 0, x: float = 0.0, alineacion := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = alineacion
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.position = Vector2(x, y)
	etiqueta.size.x = ancho
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	if interlineado != 0:
		etiqueta.add_theme_constant_override("line_spacing", interlineado)
	v.add_child(etiqueta)


## Una ficha (tu diseño) centrada en `centro`, con sombra.
func _ficha(v: SubViewport, clave: String, centro: Vector2, escala: float, grados: float = 0.0) -> void:
	var textura: Texture2D = load("res://assets/fichas/%s.png" % clave)
	var tam := textura.get_size() * escala
	var sombra := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.25)
	estilo.set_corner_radius_all(int(22 * escala))
	sombra.add_theme_stylebox_override("panel", estilo)
	sombra.size = tam
	sombra.pivot_offset = tam / 2
	sombra.position = centro - tam / 2 + Vector2(8, 10) * escala
	sombra.rotation_degrees = grados
	v.add_child(sombra)
	var ficha := TextureRect.new()
	ficha.texture = textura
	ficha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ficha.size = tam
	ficha.pivot_offset = tam / 2
	ficha.position = centro - tam / 2
	ficha.rotation_degrees = grados
	v.add_child(ficha)


## Abanico de fichas que gira alrededor de `centro` (por debajo de las fichas).
func _abanico(v: SubViewport, claves: Array, centro: Vector2, escala: float, radio: float) -> void:
	var paso := 10.0
	for i in claves.size():
		var textura: Texture2D = load("res://assets/fichas/%s.png" % claves[i])
		var tam := textura.get_size() * escala
		var ficha := TextureRect.new()
		ficha.texture = textura
		ficha.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ficha.size = tam
		ficha.pivot_offset = Vector2(tam.x / 2, tam.y + radio)
		ficha.position = centro - ficha.pivot_offset
		ficha.rotation_degrees = (i - (claves.size() - 1) / 2.0) * paso
		v.add_child(ficha)


## Una foto del juego en un marco crema.
func _foto(v: SubViewport, captura: String, rect: Rect2) -> void:
	var marco := Panel.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = CREMA
	estilo.set_corner_radius_all(18)
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 14
	marco.add_theme_stylebox_override("panel", estilo)
	marco.position = rect.position - Vector2(8, 8)
	marco.size = rect.size + Vector2(16, 16)
	v.add_child(marco)
	var imagen := Image.load_from_file(ProjectSettings.globalize_path(CAPTURAS + captura + ".png"))
	var foto := TextureRect.new()
	foto.texture = ImageTexture.create_from_image(imagen)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_SCALE
	foto.position = rect.position
	foto.size = rect.size
	v.add_child(foto)


## Franja crema abajo con un texto.
func _franja(v: SubViewport, texto: String, ancho: int) -> void:
	var alto := float(v.size.y)
	var franja := ColorRect.new()
	franja.color = CREMA
	franja.position = Vector2(0, alto - 96)
	franja.size = Vector2(ancho, 96)
	v.add_child(franja)
	_texto(v, texto, 38, ROSA, alto - 72, ancho)


func _guardar(v: SubViewport, nombre: String) -> void:
	for i in 3:
		await process_frame
	var imagen := v.get_texture().get_image()
	imagen.convert(Image.FORMAT_RGB8)
	imagen.save_png(ProjectSettings.globalize_path(CARPETA + nombre + ".png"))
	v.queue_free()
	print("Lista: ", nombre)
