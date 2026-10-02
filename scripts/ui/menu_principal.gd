class_name MenuPrincipal
extends ColorRect
## La pantalla de inicio, con diseño mexicano: papel picado, título, un abanico con
## las fichas del juego y botones grandes. También contiene la ventana de Ajustes.

signal elegido(opcion: String)  # "continuar", "jugar", "tutorial", "tarjeta", "reglas"
signal ajustes_cambiados

const CREMA := Color("fbf3e4")
const ROSA := Color("c2185b")
const CAFE := Color("3b2a1a")
## Las fichas del abanico decorativo.
const ABANICO := ["bam2", "car5", "dR", "comodin", "dV", "cir8", "flor"]

## Ajustes que se guardan (main.gd los lee y los guarda en progreso.cfg).
var ajustes := {"sonido": true, "volumen": 0.8, "velocidad": 1.0, "animaciones": true, "letra_grande": false}

var _boton_continuar: Button
var _capa_ajustes: Control
var _control_sonido: CheckButton
var _control_volumen: HSlider
var _control_animaciones: CheckButton
var _control_letra: CheckButton
var _botones_velocidad := {}


func _init() -> void:
	color = CREMA
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	var picado := PapelPicado.new()
	picado.color_fondo = CREMA
	picado.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(picado)

	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_FULL_RECT)
	columna.offset_top = 70
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 10)
	add_child(columna)

	var titulo := Label.new()
	titulo.text = "Mahjong en Español"
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", ROSA)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(titulo)
	var subtitulo := Label.new()
	subtitulo.text = "Aprende y juega · Mahjong americano · Tarjeta 2026"
	subtitulo.add_theme_font_size_override("font_size", 22)
	subtitulo.add_theme_color_override("font_color", CAFE)
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	columna.add_child(subtitulo)
	columna.add_child(_crear_abanico())

	var botones := VBoxContainer.new()
	botones.add_theme_constant_override("separation", 10)
	botones.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	columna.add_child(botones)
	_boton_continuar = _boton_grande("Continuar partida", "continuar", true)
	botones.add_child(_boton_continuar)
	botones.add_child(_boton_grande("Jugar", "jugar", true))
	botones.add_child(_boton_grande("Aprender a jugar", "tutorial", false))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 10)
	botones.add_child(fila)
	fila.add_child(_boton_pequeno("Tarjeta 2026", func(): elegido.emit("tarjeta")))
	fila.add_child(_boton_pequeno("Reglas", func(): elegido.emit("reglas")))
	fila.add_child(_boton_pequeno("Ajustes", abrir_ajustes))

	# La versión, abajo a la derecha: así se sabe qué versión tiene instalada cada quien.
	var version := Label.new()
	version.text = "Versión %s" % ProjectSettings.get_setting("application/config/version", "")
	version.add_theme_font_size_override("font_size", 16)
	version.add_theme_color_override("font_color", CAFE)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	version.grow_vertical = Control.GROW_DIRECTION_BEGIN
	version.offset_right = -20
	version.offset_bottom = -12
	add_child(version)

	_crear_ajustes()


## Muestra el menú. `hay_partida` indica si se puede continuar una partida empezada.
func abrir(hay_partida: bool) -> void:
	_boton_continuar.visible = hay_partida
	visible = true


func abrir_ajustes() -> void:
	_control_sonido.button_pressed = ajustes["sonido"]
	_control_volumen.value = ajustes["volumen"]
	_control_animaciones.button_pressed = ajustes["animaciones"]
	_control_letra.button_pressed = ajustes.get("letra_grande", false)
	_marcar_velocidad()
	_capa_ajustes.visible = true


func _crear_abanico() -> Control:
	var caja := Control.new()
	caja.custom_minimum_size = Vector2(0, 190)
	var centro := Vector2(640, 330)
	for i in ABANICO.size():
		var clave: String = ABANICO[i]
		var ficha := FichaVisual.new(Ficha.desde_clave(clave))
		ficha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var angulo := deg_to_rad(-36.0 + 72.0 * i / (ABANICO.size() - 1))
		ficha.pivot_offset = Vector2(FichaVisual.TAMANO.x / 2, FichaVisual.TAMANO.y + 170)
		ficha.position = centro - ficha.pivot_offset
		ficha.rotation = angulo
		ficha.scale = Vector2(1.15, 1.15)
		caja.add_child(ficha)
	return caja


func _boton_grande(texto: String, opcion: String, principal: bool) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(420, 64)
	b.add_theme_font_size_override("font_size", 26)
	var base := ROSA if principal else Color("1f6b3f")
	for estado in ["normal", "hover", "pressed", "focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = base.lightened(0.1) if estado == "hover" else (base.darkened(0.15) if estado == "pressed" else base)
		estilo.set_corner_radius_all(14)
		b.add_theme_stylebox_override(estado, estilo)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.pressed.connect(func(): elegido.emit(opcion))
	return b


func _boton_pequeno(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(133, 52)
	b.add_theme_font_size_override("font_size", 19)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = Color("f1e2c6") if estado != "hover" else Color("ead3aa")
		estilo.border_color = Color("c9a979")
		estilo.set_border_width_all(2)
		estilo.set_corner_radius_all(12)
		b.add_theme_stylebox_override(estado, estilo)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, CAFE)
	b.pressed.connect(accion)
	return b


# =============================================================================
#  AJUSTES
# =============================================================================

func _crear_ajustes() -> void:
	_capa_ajustes = ColorRect.new()
	(_capa_ajustes as ColorRect).color = Color(0, 0, 0, 0.55)
	_capa_ajustes.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa_ajustes.mouse_filter = Control.MOUSE_FILTER_STOP
	_capa_ajustes.visible = false
	add_child(_capa_ajustes)

	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = CREMA
	estilo.border_color = ROSA
	estilo.set_border_width_all(4)
	estilo.set_corner_radius_all(18)
	estilo.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", estilo)
	panel.custom_minimum_size = Vector2(620, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_capa_ajustes.add_child(panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	panel.add_child(caja)
	caja.add_child(_etiqueta("Ajustes", 34, ROSA))

	_control_sonido = CheckButton.new()
	_control_sonido.text = "Sonido"
	_control_sonido.add_theme_font_size_override("font_size", 22)
	_colores_cafe(_control_sonido)
	_control_sonido.toggled.connect(func(v): _cambiar("sonido", v))
	caja.add_child(_control_sonido)

	var fila_volumen := HBoxContainer.new()
	fila_volumen.add_child(_etiqueta("Volumen", 22, CAFE))
	_control_volumen = HSlider.new()
	_control_volumen.min_value = 0.0
	_control_volumen.max_value = 1.0
	_control_volumen.step = 0.05
	_control_volumen.custom_minimum_size = Vector2(320, 40)
	_control_volumen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_control_volumen.value_changed.connect(func(v): _cambiar("volumen", v))
	fila_volumen.add_child(_control_volumen)
	caja.add_child(fila_volumen)

	caja.add_child(_etiqueta("Velocidad de los rivales", 22, CAFE))
	var fila_velocidad := HBoxContainer.new()
	fila_velocidad.add_theme_constant_override("separation", 10)
	caja.add_child(fila_velocidad)
	for opcion in [["Lenta", 1.5], ["Normal", 1.0], ["Rápida", 0.6]]:
		var b := _boton_pequeno(opcion[0], func():
			_cambiar("velocidad", opcion[1])
			_marcar_velocidad())
		b.custom_minimum_size.x = 170
		_botones_velocidad[opcion[1]] = b
		fila_velocidad.add_child(b)

	_control_animaciones = CheckButton.new()
	_control_animaciones.text = "Animaciones y confeti"
	_control_animaciones.add_theme_font_size_override("font_size", 22)
	_colores_cafe(_control_animaciones)
	_control_animaciones.toggled.connect(func(v): _cambiar("animaciones", v))
	caja.add_child(_control_animaciones)

	_control_letra = CheckButton.new()
	_control_letra.text = "Letra grande (más fácil de leer)"
	_control_letra.add_theme_font_size_override("font_size", 22)
	_colores_cafe(_control_letra)
	_control_letra.toggled.connect(func(v): _cambiar("letra_grande", v))
	caja.add_child(_control_letra)

	var cerrar := _boton_grande("Listo", "", true)
	cerrar.custom_minimum_size = Vector2(200, 56)
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_END
	for c in cerrar.pressed.get_connections():
		cerrar.pressed.disconnect(c["callable"])
	cerrar.pressed.connect(func(): _capa_ajustes.visible = false)
	caja.add_child(cerrar)


func _cambiar(clave: String, valor) -> void:
	ajustes[clave] = valor
	ajustes_cambiados.emit()


func _marcar_velocidad() -> void:
	for v in _botones_velocidad:
		var b: Button = _botones_velocidad[v]
		var estilo: StyleBoxFlat = b.get_theme_stylebox("normal")
		estilo.border_color = ROSA if is_equal_approx(v, ajustes["velocidad"]) else Color("c9a979")
		estilo.set_border_width_all(4 if is_equal_approx(v, ajustes["velocidad"]) else 2)


func _etiqueta(texto: String, tamano: int, color_texto: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color_texto)
	return l


func _colores_cafe(control: Control) -> void:
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		control.add_theme_color_override(c, CAFE)
