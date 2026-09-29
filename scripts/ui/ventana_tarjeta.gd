class_name VentanaTarjeta
extends ColorRect
## La «Tarjeta 2026» completa, con diseño mexicano: papel picado arriba y cada mano
## dibujada con las fichas del juego, separada por secciones.
## Al tocar una mano se elige como objetivo.

signal mano_elegida(nombre: String)

const CREMA := Color("fbf3e4")
const ROSA := Color("c2185b")
const CAFE := Color("3b2a1a")
const COLORES_SECCION := [Color("c2185b"), Color("1f6b3f"), Color("b5441f"), Color("1f4e8c"),
	Color("6a3d9a"), Color("e0a100")]
const ESCALA_FICHA := 0.46

## Por cada mano: la etiqueta que muestra cuántas fichas faltan y el fondo de su fila.
var _chips := {}
var _filas := {}


func _init() -> void:
	color = Color(0, 0, 0, 0.6)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func _ready() -> void:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = CREMA
	estilo.border_color = ROSA
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", estilo)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_top = 16
	panel.offset_bottom = -16
	add_child(panel)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 6)
	panel.add_child(columna)

	var picado := PapelPicado.new()
	picado.color_fondo = CREMA
	columna.add_child(picado)
	columna.add_child(_crear_cabecera())

	var desplazamiento := ScrollContainer.new()
	desplazamiento.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desplazamiento.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columna.add_child(_con_margen(desplazamiento, 20, 0))
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	desplazamiento.add_child(lista)

	var manos := Tarjeta.manos()
	for i in Tarjeta.SECCIONES.size():
		var seccion: String = Tarjeta.SECCIONES[i]
		var de_seccion := manos.filter(func(m): return m["seccion"] == seccion)
		lista.add_child(_cabecera_seccion(seccion, de_seccion.size(), COLORES_SECCION[i % COLORES_SECCION.size()]))
		for j in de_seccion.size():
			lista.add_child(_fila_mano(de_seccion[j], j % 2 == 0))

	var pie := Label.new()
	pie.text = "Toca una mano para elegirla como objetivo.   X = puedes cantar descartes   ·   C = oculta (no se puede cantar, salvo para Mahjong)"
	pie.add_theme_font_size_override("font_size", 14)
	pie.add_theme_color_override("font_color", CAFE)
	pie.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(_con_margen(pie, 20, 8))


## Abre la tarjeta. `analisis` es la lista de Validador.manos_mas_cercanas (o [] si no hay),
## para mostrar cuántas fichas te faltan en cada mano.
func abrir(analisis: Array, objetivo_nombre: String, mostrar_faltan: bool) -> void:
	for a in analisis:
		var nombre: String = a["mano"]["nombre"]
		var chip: Label = _chips[nombre]
		chip.visible = mostrar_faltan
		if a["faltan"] == Validador.IMPOSIBLE:
			chip.text = "No posible"
		else:
			chip.text = "Faltan %d" % a["faltan"]
	for nombre in _filas:
		var estilo: StyleBoxFlat = _filas[nombre].get_theme_stylebox("panel")
		estilo.border_color = ROSA if nombre == objetivo_nombre else Color(0, 0, 0, 0)
	visible = true


func _crear_cabecera() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)

	var comodin := _imagen_ficha("comodin", 0.55)
	fila.add_child(comodin)

	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", -4)
	var titulo := Label.new()
	titulo.text = Tarjeta.TITULO
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_color_override("font_color", ROSA)
	textos.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = "Mahjong Americano · %d manos · Ejemplos con A = Nopal, B = Picado, C = Sol y X = 1" % Tarjeta.manos().size()
	subtitulo.add_theme_font_size_override("font_size", 15)
	subtitulo.add_theme_color_override("font_color", CAFE)
	textos.add_child(subtitulo)
	fila.add_child(textos)

	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(espacio)
	fila.add_child(_imagen_ficha("flor", 0.55))

	var cerrar := Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(140, 52)
	cerrar.add_theme_font_size_override("font_size", 20)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = ROSA.darkened(0.15) if estado == "pressed" else ROSA
		estilo.set_corner_radius_all(10)
		cerrar.add_theme_stylebox_override(estado, estilo)
	for color_texto in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		cerrar.add_theme_color_override(color_texto, Color.WHITE)
	cerrar.pressed.connect(func(): visible = false)
	fila.add_child(cerrar)
	return _con_margen(fila, 20, 0)


func _cabecera_seccion(nombre: String, cuantas: int, color_seccion: Color) -> Control:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color_seccion
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 14
	estilo.content_margin_top = 4
	estilo.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", estilo)
	var etiqueta := Label.new()
	etiqueta.text = "%s   ·   %d manos" % [nombre, cuantas]
	etiqueta.add_theme_font_size_override("font_size", 22)
	etiqueta.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(etiqueta)
	return panel


func _fila_mano(mano: Dictionary, par: bool) -> Control:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("fffaf0") if par else Color("f6ead3")
	estilo.set_corner_radius_all(8)
	estilo.set_border_width_all(3)
	estilo.border_color = Color(0, 0, 0, 0)
	estilo.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", estilo)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.gui_input.connect(func(evento: InputEvent):
		if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed:
			mano_elegida.emit(mano["nombre"])
			visible = false)
	_filas[mano["nombre"]] = panel

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fila)

	# Nombre y explicación.
	var textos := VBoxContainer.new()
	textos.custom_minimum_size.x = 330
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nombre := Label.new()
	nombre.text = mano["nombre"]
	nombre.add_theme_font_size_override("font_size", 19)
	nombre.add_theme_color_override("font_color", CAFE)
	textos.add_child(nombre)
	var explicacion := Label.new()
	explicacion.text = mano["explicacion"]
	explicacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explicacion.custom_minimum_size.x = 330
	explicacion.add_theme_font_size_override("font_size", 12)
	explicacion.add_theme_color_override("font_color", Color("6b5540"))
	textos.add_child(explicacion)
	fila.add_child(textos)

	# La mano dibujada con las fichas del juego.
	var fichas := HBoxContainer.new()
	fichas.add_theme_constant_override("separation", 0)
	fichas.alignment = BoxContainer.ALIGNMENT_BEGIN
	fichas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fichas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var anterior_suelta := false
	var primero := true
	for grupo in Tarjeta.ejemplo(mano):
		# Un hueco entre grupos, salvo entre fichas sueltas seguidas (como "2026").
		var suelta: bool = grupo.size() == 1
		if not primero and not (suelta and anterior_suelta):
			var hueco := Control.new()
			hueco.custom_minimum_size.x = 9
			fichas.add_child(hueco)
		for ficha in grupo:
			fichas.add_child(_ficha_pequena(ficha))
		anterior_suelta = suelta
		primero = false
	fila.add_child(fichas)

	var chip := Label.new()
	chip.add_theme_font_size_override("font_size", 15)
	chip.add_theme_color_override("font_color", Color("1f6b3f"))
	chip.custom_minimum_size.x = 90
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.visible = false
	_chips[mano["nombre"]] = chip
	fila.add_child(chip)

	var puntos := Label.new()
	puntos.text = str(mano["puntos"])
	puntos.add_theme_font_size_override("font_size", 22)
	puntos.add_theme_color_override("font_color", CAFE)
	puntos.custom_minimum_size.x = 36
	puntos.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fila.add_child(puntos)

	var marca := Label.new()
	marca.text = "C" if mano["oculta"] else "X"
	marca.add_theme_font_size_override("font_size", 22)
	marca.add_theme_color_override("font_color", ROSA if mano["oculta"] else Color("1f6b3f"))
	marca.custom_minimum_size.x = 24
	fila.add_child(marca)
	return panel


func _ficha_pequena(ficha: Ficha) -> Control:
	var fv := FichaVisual.new(ficha)
	fv.scale = Vector2(ESCALA_FICHA, ESCALA_FICHA)
	fv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hueco := Control.new()
	hueco.custom_minimum_size = FichaVisual.TAMANO * ESCALA_FICHA
	hueco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hueco.add_child(fv)
	return hueco


func _imagen_ficha(clave: String, escala: float) -> Control:
	var ficha := Ficha.desde_clave(clave)
	var fv := FichaVisual.new(ficha)
	fv.scale = Vector2(escala, escala)
	fv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hueco := Control.new()
	hueco.custom_minimum_size = FichaVisual.TAMANO * escala
	hueco.add_child(fv)
	return hueco


func _con_margen(nodo: Control, horizontal: int, vertical: int) -> MarginContainer:
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", horizontal)
	margen.add_theme_constant_override("margin_right", horizontal)
	margen.add_theme_constant_override("margin_top", vertical)
	margen.add_theme_constant_override("margin_bottom", vertical)
	margen.size_flags_vertical = nodo.size_flags_vertical
	margen.add_child(nodo)
	return margen
