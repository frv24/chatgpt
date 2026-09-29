extends Control
## Pantalla principal: modo SOLITARIO para aprender.
##
## Cómo se juega:
##   1. Recibes 13 fichas.
##   2. En cada turno robas 1 ficha (tienes 14) y descartas 1 (vuelves a 13).
##   3. Ganas cuando tus 14 fichas forman una mano de la tarjeta.
##
## Toda la interfaz se crea desde código para que puedas leerla de arriba abajo.
## (Cuando te sientas cómodo con Godot, puedes rehacerla en el editor visual).

enum Fase { ROBAR, DESCARTAR, FIN }

const COLOR_FONDO := Color("0f5132")  # verde tapete

var mazo: Mazo
var mano: Array[Ficha] = []
var descartes: Array[Ficha] = []
var fase := Fase.ROBAR
var manos_tarjeta := Tarjeta.manos()

## Mano de la tarjeta que el jugador intenta conseguir (para los consejos).
var objetivo: Dictionary = {}
## Si es true, el jugador eligió el objetivo a mano y no lo cambiamos solos.
var objetivo_elegido := false
var seleccionada: FichaVisual = null

# Nodos de la interfaz (se crean en _crear_interfaz).
var _fila_mano: HBoxContainer
var _zona_descartes: HFlowContainer
var _lista_tarjeta: ItemList
var _texto_objetivo: Label
var _mensaje: Label
var _info_muro: Label
var _boton_robar: Button
var _boton_descartar: Button
var _interruptor_consejos: CheckButton
## Análisis de cada fila de la lista de la tarjeta (mismo orden que la lista).
var _analisis_lista: Array[Dictionary] = []


func _ready() -> void:
	_crear_interfaz()
	nueva_partida()


# =============================================================================
#  REGLAS DEL JUEGO
# =============================================================================

func nueva_partida() -> void:
	mazo = Mazo.new()
	mazo.barajar()
	mano = mazo.repartir(13)
	descartes.clear()
	objetivo_elegido = false
	seleccionada = null
	_ordenar_mano()
	fase = Fase.ROBAR
	_mostrar_mensaje("Tienes 13 fichas. Pulsa «Robar» para coger una del muro.")
	_refrescar()


func robar() -> void:
	if fase != Fase.ROBAR:
		return
	var nueva := mazo.robar()
	if nueva == null:
		fase = Fase.FIN
		_mostrar_mensaje("Se acabó el muro. ¡Empate! Pulsa «Nueva partida» para volver a intentarlo.")
		_refrescar()
		return
	mano.append(nueva)

	var ganadora := Validador.buscar_mano_ganadora(mano, manos_tarjeta)
	if not ganadora.is_empty():
		fase = Fase.FIN
		_mostrar_mensaje("¡MAHJONG! Completaste «%s» (%d puntos)." % [ganadora["nombre"], ganadora["puntos"]])
	else:
		fase = Fase.DESCARTAR
		_mostrar_mensaje("Has robado: %s. Ahora toca la ficha que quieras descartar y pulsa «Descartar»." % nueva.nombre())
	_refrescar()


func descartar() -> void:
	if fase != Fase.DESCARTAR:
		return
	if seleccionada == null:
		_mostrar_mensaje("Primero toca una ficha para seleccionarla.")
		return
	var ficha := seleccionada.ficha
	mano.erase(ficha)
	descartes.append(ficha)
	seleccionada = null
	fase = Fase.ROBAR
	var aviso := ""
	if ficha.es_comodin():
		aviso = " Cuidado: ¡los comodines casi nunca se descartan!"
	_mostrar_mensaje("Descartaste: %s.%s Pulsa «Robar» para seguir." % [ficha.nombre(), aviso])
	_refrescar()


func _ordenar_mano() -> void:
	mano.sort_custom(func(a: Ficha, b: Ficha): return a.orden() < b.orden())


# =============================================================================
#  EVENTOS DE LA INTERFAZ
# =============================================================================

func _al_tocar_ficha(fv: FichaVisual) -> void:
	if fase != Fase.DESCARTAR:
		_mostrar_mensaje(fv.ficha.nombre() + ". Puedes arrastrar las fichas para ordenarlas a tu gusto.")
		return
	if seleccionada == fv:
		seleccionada = null
	else:
		seleccionada = fv
	_refrescar_mano()


func _al_soltar_ficha(origen: FichaVisual, destino: FichaVisual) -> void:
	# Mueve la ficha arrastrada al lugar de la ficha sobre la que se soltó.
	var indice_destino := mano.find(destino.ficha)
	mano.erase(origen.ficha)
	mano.insert(indice_destino, origen.ficha)
	_refrescar_mano()


func _al_pulsar_ordenar() -> void:
	_ordenar_mano()
	_refrescar_mano()


func _al_elegir_objetivo(indice: int) -> void:
	objetivo = _analisis_lista[indice]["mano"]
	objetivo_elegido = true
	_refrescar()


# =============================================================================
#  DIBUJAR EL ESTADO EN PANTALLA
# =============================================================================

func _refrescar() -> void:
	_info_muro.text = "Fichas en el muro: %d" % mazo.quedan()
	_boton_robar.disabled = fase != Fase.ROBAR
	_boton_descartar.disabled = fase != Fase.DESCARTAR
	_refrescar_tarjeta()
	_refrescar_mano()
	_refrescar_descartes()


func _refrescar_tarjeta() -> void:
	# Ordena todas las manos de la más cercana a la más lejana.
	_analisis_lista = Validador.manos_mas_cercanas(mano, manos_tarjeta, manos_tarjeta.size())
	if not objetivo_elegido:
		objetivo = _analisis_lista[0]["mano"]

	_lista_tarjeta.clear()
	for i in _analisis_lista.size():
		var a := _analisis_lista[i]
		var texto := "%s   %s" % [a["mano"]["nombre"], a["mano"]["patron"]]
		if _interruptor_consejos.button_pressed:
			texto = "Faltan %d · %s" % [a["faltan"], texto]
		_lista_tarjeta.add_item(texto)
		if a["mano"]["nombre"] == objetivo["nombre"]:
			_lista_tarjeta.select(i)

	var texto_objetivo := "Objetivo: %s\n%s" % [objetivo["nombre"], objetivo["explicacion"]]
	if _interruptor_consejos.button_pressed:
		texto_objetivo += "\n\nConsejo: " + objetivo["consejo"]
	_texto_objetivo.text = texto_objetivo


func _refrescar_mano() -> void:
	for hijo in _fila_mano.get_children():
		hijo.queue_free()

	var consejos := _interruptor_consejos.button_pressed
	var ids_utiles: Array[int] = []
	if consejos:
		ids_utiles = Validador.ids_utiles(mano, Validador.analizar(mano, objetivo))

	var id_seleccionada := seleccionada.ficha.id if seleccionada else -1
	seleccionada = null
	for ficha in mano:
		var fv := FichaVisual.new(ficha)
		fv.mostrar_consejo = consejos
		fv.util = ficha.id in ids_utiles
		if ficha.id == id_seleccionada:
			fv.seleccionada = true
			seleccionada = fv
		fv.tocada.connect(_al_tocar_ficha)
		fv.soltada_encima.connect(_al_soltar_ficha)
		_fila_mano.add_child(fv)


func _refrescar_descartes() -> void:
	for hijo in _zona_descartes.get_children():
		hijo.queue_free()
	for ficha in descartes:
		var fv := FichaVisual.new(ficha)
		fv.scale = Vector2(0.7, 0.7)
		fv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# El contenedor reserva el tamaño ya reducido.
		var hueco := Control.new()
		hueco.custom_minimum_size = FichaVisual.TAMANO * 0.7
		hueco.add_child(fv)
		_zona_descartes.add_child(hueco)


func _mostrar_mensaje(texto: String) -> void:
	_mensaje.text = texto


# =============================================================================
#  CREAR LA INTERFAZ
# =============================================================================

func _crear_interfaz() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var fondo := ColorRect.new()
	fondo.color = COLOR_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	add_child(margen)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 12)
	margen.add_child(columna)

	# --- Barra superior ---
	var barra := HBoxContainer.new()
	columna.add_child(barra)
	var titulo := Label.new()
	titulo.text = "Mahjong Americano · Modo aprendizaje"
	titulo.add_theme_font_size_override("font_size", 26)
	barra.add_child(titulo)
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(espacio)
	_info_muro = Label.new()
	barra.add_child(_info_muro)
	_interruptor_consejos = CheckButton.new()
	_interruptor_consejos.text = "Consejos"
	_interruptor_consejos.button_pressed = true
	_interruptor_consejos.toggled.connect(func(_activo): _refrescar())
	barra.add_child(_interruptor_consejos)
	barra.add_child(_boton("Nueva partida", nueva_partida))

	# --- Zona central: descartes a la izquierda, tarjeta a la derecha ---
	var centro := HBoxContainer.new()
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centro.add_theme_constant_override("separation", 16)
	columna.add_child(centro)

	var panel_descartes := _panel("Descartes")
	panel_descartes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.add_child(panel_descartes)
	var desplazamiento := ScrollContainer.new()
	desplazamiento.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_descartes.get_child(0).add_child(desplazamiento)
	_zona_descartes = HFlowContainer.new()
	_zona_descartes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazamiento.add_child(_zona_descartes)

	var panel_tarjeta := _panel("Tarjeta de manos (toca una para elegirla como objetivo)")
	panel_tarjeta.custom_minimum_size.x = 560
	centro.add_child(panel_tarjeta)
	_lista_tarjeta = ItemList.new()
	_lista_tarjeta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista_tarjeta.item_selected.connect(_al_elegir_objetivo)
	panel_tarjeta.get_child(0).add_child(_lista_tarjeta)
	_texto_objetivo = Label.new()
	_texto_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto_objetivo.custom_minimum_size.y = 110
	panel_tarjeta.get_child(0).add_child(_texto_objetivo)

	# --- Mensaje para el jugador ---
	_mensaje = Label.new()
	_mensaje.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mensaje.add_theme_font_size_override("font_size", 20)
	_mensaje.add_theme_color_override("font_color", Color("ffe082"))
	columna.add_child(_mensaje)

	# --- Tu mano ---
	_fila_mano = HBoxContainer.new()
	_fila_mano.alignment = BoxContainer.ALIGNMENT_CENTER
	_fila_mano.add_theme_constant_override("separation", 4)
	_fila_mano.custom_minimum_size.y = FichaVisual.TAMANO.y
	columna.add_child(_fila_mano)

	# --- Botones de acción (grandes, para dedos) ---
	var acciones := HBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_CENTER
	acciones.add_theme_constant_override("separation", 16)
	columna.add_child(acciones)
	_boton_robar = _boton("Robar", robar)
	_boton_descartar = _boton("Descartar", descartar)
	acciones.add_child(_boton_robar)
	acciones.add_child(_boton_descartar)
	acciones.add_child(_boton("Ordenar", _al_pulsar_ordenar))


## Crea un botón grande con texto y la función que ejecuta al pulsarlo.
func _boton(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(160, 56)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(accion)
	return b


## Crea un panel con título. Los elementos se añaden a panel.get_child(0).
func _panel(titulo: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0, 0, 0, 0.25)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", estilo)
	var caja := VBoxContainer.new()
	panel.add_child(caja)
	var etiqueta := Label.new()
	etiqueta.text = titulo
	etiqueta.add_theme_font_size_override("font_size", 18)
	caja.add_child(etiqueta)
	return panel
