extends Control
## Pantalla principal: modo SOLITARIO para aprender.
##
## Cómo se juega:
##   1. Recibes 13 fichas (y los 3 rivales de la máquina, otras 13 cada uno).
##   2. CHARLESTON: intercambias fichas con los rivales para mejorar tu mano.
##   3. En cada turno robas 1 ficha (tienes 14) y descartas 1 (vuelves a 13).
##   4. Ganas cuando tus 14 fichas forman una mano de la tarjeta.
##   (Los rivales todavía no juegan turnos: solo participan en el Charleston).
##
## Toda la interfaz se crea desde código para que puedas leerla de arriba abajo.
## (Cuando te sientas cómodo con Godot, puedes rehacerla en el editor visual).

enum Fase { CHARLESTON, ROBAR, DESCARTAR, FIN }

const COLOR_FONDO := Color("0f5132")  # verde tapete

var mazo: Mazo
var mano: Array[Ficha] = []
var descartes: Array[Ficha] = []
var fase := Fase.CHARLESTON
var manos_tarjeta := Tarjeta.manos()
var charleston: Charleston
## true si el jugador decidió no hacer el segundo Charleston.
var segundo_saltado := false

## Mano de la tarjeta que el jugador intenta conseguir (para los consejos).
var objetivo: Dictionary = {}
## Si es true, el jugador eligió el objetivo a mano y no lo cambiamos solos.
var objetivo_elegido := false
## Ids de las fichas seleccionadas (1 para descartar, hasta 3 en el Charleston).
var seleccion: Array[int] = []
## Ids de las fichas recién recibidas o robadas (se pintan en amarillo).
var ids_nuevas: Array[int] = []

# Nodos de la interfaz (se crean en _crear_interfaz).
var _fila_mano: HBoxContainer
var _titulo_izquierda: Label
var _zona_descartes: ScrollContainer
var _fichas_descartadas: HFlowContainer
var _texto_charleston: Label
var _lista_tarjeta: ItemList
var _texto_objetivo: Label
var _mensaje: Label
var _info_muro: Label
var _interruptor_consejos: CheckButton
var _boton_robar: Button
var _boton_descartar: Button
var _boton_pasar: Button
var _boton_sugerir: Button
var _boton_segundo_si: Button
var _boton_segundo_no: Button
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
	# Se reparten 13 fichas a cada uno de los 4 jugadores (0 = tú).
	var manos := [mazo.repartir(13), mazo.repartir(13), mazo.repartir(13), mazo.repartir(13)]
	charleston = Charleston.new(manos, manos_tarjeta)
	mano = charleston.mano_jugador()
	descartes.clear()
	objetivo_elegido = false
	segundo_saltado = false
	seleccion.clear()
	ids_nuevas.clear()
	_ordenar_mano()
	fase = Fase.CHARLESTON
	_mostrar_mensaje("Empieza el Charleston. Mira la tarjeta, elige tu mano objetivo y toca 3 fichas que no te sirvan.")
	_refrescar()


# --- Charleston ---

func pasar_fichas() -> void:
	if fase != Fase.CHARLESTON:
		return
	var pase := _fichas_seleccionadas()
	var error := charleston.validar_pase(pase)
	if error != "":
		_mostrar_mensaje(error)
		return
	var direccion := charleston.direccion_actual()
	var recibidas := charleston.pasar(pase)
	seleccion.clear()
	ids_nuevas.clear()
	for f in recibidas:
		ids_nuevas.append(f.id)

	var texto := "Pasaste %d fichas %s" % [pase.size(), Charleston.FLECHA[direccion]]
	if recibidas.is_empty():
		texto += " y no recibiste ninguna."
	else:
		texto += " y recibiste: %s (en amarillo)." % _nombres(recibidas)
	_despues_de_un_paso(texto)


func decidir_segundo_charleston(quiere: bool) -> void:
	charleston.decidir_segundo(quiere)
	segundo_saltado = not quiere
	_despues_de_un_paso("Segundo Charleston." if quiere else "Sin segundo Charleston.")


func _despues_de_un_paso(texto: String) -> void:
	if charleston.terminado():
		fase = Fase.ROBAR
		texto += " ¡Charleston terminado! Pulsa «Robar» para empezar a jugar."
	else:
		var descripcion := charleston.descripcion()
		texto += " " + descripcion + ("" if descripcion.ends_with("?") else ".")
	_mostrar_mensaje(texto)
	_refrescar()


# --- Turnos de juego ---

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
	ids_nuevas.clear()
	ids_nuevas.append(nueva.id)

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
	var elegidas := _fichas_seleccionadas()
	if elegidas.is_empty():
		_mostrar_mensaje("Primero toca una ficha para seleccionarla.")
		return
	var ficha := elegidas[0]
	mano.erase(ficha)
	descartes.append(ficha)
	seleccion.clear()
	ids_nuevas.clear()
	fase = Fase.ROBAR
	var aviso := ""
	if ficha.es_comodin():
		aviso = " Cuidado: ¡los comodines casi nunca se descartan!"
	_mostrar_mensaje("Descartaste: %s.%s Pulsa «Robar» para seguir." % [ficha.nombre(), aviso])
	_refrescar()


## Selecciona las fichas que el asesor recomienda soltar y explica por qué.
func sugerir() -> void:
	var cantidad := 1 if fase == Fase.DESCARTAR else Charleston.FICHAS_POR_PASE
	var sugeridas := Asesor.fichas_que_sobran(mano, manos_tarjeta, cantidad)
	seleccion.clear()
	for f in sugeridas:
		seleccion.append(f.id)
	var boton := "«Descartar»" if fase == Fase.DESCARTAR else "«Pasar»"
	_mostrar_mensaje("%s Pulsa %s si estás de acuerdo." % [Asesor.explicar(sugeridas, mano, manos_tarjeta), boton])
	_refrescar_mano()


func _ordenar_mano() -> void:
	mano.sort_custom(func(a: Ficha, b: Ficha): return a.orden() < b.orden())


func _fichas_seleccionadas() -> Array[Ficha]:
	var elegidas: Array[Ficha] = []
	for f in mano:
		if f.id in seleccion:
			elegidas.append(f)
	return elegidas


func _pasando_fichas() -> bool:
	return fase == Fase.CHARLESTON and charleston.etapa != Charleston.Etapa.PREGUNTA_SEGUNDO


func _nombres(fichas: Array[Ficha]) -> String:
	var nombres: Array[String] = []
	for f in fichas:
		nombres.append(f.nombre())
	return ", ".join(nombres)


# =============================================================================
#  EVENTOS DE LA INTERFAZ
# =============================================================================

func _al_tocar_ficha(fv: FichaVisual) -> void:
	var id := fv.ficha.id
	if _pasando_fichas():
		if fv.ficha.es_comodin():
			_mostrar_mensaje("Los comodines no se pueden pasar en el Charleston. ¡Guárdalos, valen mucho!")
			return
		if id in seleccion:
			seleccion.erase(id)
		elif seleccion.size() >= Charleston.FICHAS_POR_PASE:
			_mostrar_mensaje("Ya elegiste 3 fichas. Toca una elegida para quitarla, o pulsa «Pasar».")
			return
		else:
			seleccion.append(id)
		_mostrar_mensaje("%s · Elegidas: %d de 3." % [charleston.descripcion(), seleccion.size()])
	elif fase == Fase.DESCARTAR:
		var ya_estaba := id in seleccion
		seleccion.clear()
		if not ya_estaba:
			seleccion.append(id)
	else:
		_mostrar_mensaje(fv.ficha.nombre() + ". Puedes arrastrar las fichas para ordenarlas a tu gusto.")
		return
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
	_refrescar_botones()
	_refrescar_tarjeta()
	_refrescar_mano()
	_refrescar_panel_izquierdo()


func _refrescar_botones() -> void:
	var en_charleston := fase == Fase.CHARLESTON
	var pregunta := en_charleston and charleston.etapa == Charleston.Etapa.PREGUNTA_SEGUNDO
	_boton_pasar.visible = _pasando_fichas()
	_boton_segundo_si.visible = pregunta
	_boton_segundo_no.visible = pregunta
	_boton_robar.visible = not en_charleston
	_boton_descartar.visible = not en_charleston
	_boton_robar.disabled = fase != Fase.ROBAR
	_boton_descartar.disabled = fase != Fase.DESCARTAR
	_boton_sugerir.disabled = not (_pasando_fichas() or fase == Fase.DESCARTAR)


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

	for ficha in mano:
		var fv := FichaVisual.new(ficha)
		fv.mostrar_consejo = consejos
		fv.util = ficha.id in ids_utiles
		fv.nueva = ficha.id in ids_nuevas
		fv.seleccionada = ficha.id in seleccion
		fv.tocada.connect(_al_tocar_ficha)
		fv.soltada_encima.connect(_al_soltar_ficha)
		_fila_mano.add_child(fv)


## El panel de la izquierda muestra los pasos del Charleston o, al jugar, los descartes.
func _refrescar_panel_izquierdo() -> void:
	var en_charleston := fase == Fase.CHARLESTON
	_texto_charleston.visible = en_charleston
	_zona_descartes.visible = not en_charleston
	if en_charleston:
		_titulo_izquierda.text = "Charleston: intercambio de fichas"
		_texto_charleston.text = _texto_pasos_charleston()
		return

	_titulo_izquierda.text = "Descartes"
	for hijo in _fichas_descartadas.get_children():
		hijo.queue_free()
	for ficha in descartes:
		var fv := FichaVisual.new(ficha)
		fv.scale = Vector2(0.7, 0.7)
		fv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# El contenedor reserva el tamaño ya reducido.
		var hueco := Control.new()
		hueco.custom_minimum_size = FichaVisual.TAMANO * 0.7
		hueco.add_child(fv)
		_fichas_descartadas.add_child(hueco)


## Lista de pasos con marcas: ✓ hecho, ▶ ahora, (vacío) pendiente.
func _texto_pasos_charleston() -> String:
	var etapa := charleston.etapa
	var lineas: Array[String] = ["Primer Charleston (obligatorio):"]
	for i in 3:
		var marca := "   "
		if etapa != Charleston.Etapa.PRIMERO or i < charleston.indice_pase:
			marca = "✓"
		elif i == charleston.indice_pase:
			marca = "▶"
		var d: int = Charleston.ORDEN_PRIMERO[i]
		lineas.append("   %s  %d. Pasar a %s %s" % [marca, i + 1, Charleston.NOMBRE_DIRECCION[d], Charleston.FLECHA[d]])

	lineas.append("Segundo Charleston (opcional):" + ("   saltado" if segundo_saltado else ""))
	if not segundo_saltado:
		for i in 3:
			var marca := "   "
			if etapa == Charleston.Etapa.CORTESIA or (etapa == Charleston.Etapa.SEGUNDO and i < charleston.indice_pase):
				marca = "✓"
			elif etapa == Charleston.Etapa.SEGUNDO and i == charleston.indice_pase:
				marca = "▶"
			var d: int = Charleston.ORDEN_SEGUNDO[i]
			lineas.append("   %s  %d. Pasar a %s %s" % [marca, i + 4, Charleston.NOMBRE_DIRECCION[d], Charleston.FLECHA[d]])

	lineas.append("Pase de cortesía: 0 a 3 fichas ENFRENTE ↑" + ("   ▶" if etapa == Charleston.Etapa.CORTESIA else ""))
	lineas.append("")
	lineas.append("¿Para qué sirve? Para cambiar las fichas que no te sirven por otras que quizá sí.")
	lineas.append("Truco: elige tu mano objetivo en la tarjeta y pasa lo que no encaje (lo apagado).")
	lineas.append("Los comodines nunca se pueden pasar.")
	return "\n".join(lineas)


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

	# --- Zona central: Charleston/descartes a la izquierda, tarjeta a la derecha ---
	var centro := HBoxContainer.new()
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	centro.add_theme_constant_override("separation", 16)
	columna.add_child(centro)

	var panel_izquierdo := _panel("")
	panel_izquierdo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.add_child(panel_izquierdo)
	var caja_izquierda := panel_izquierdo.get_child(0)
	_titulo_izquierda = caja_izquierda.get_child(0) as Label
	_texto_charleston = Label.new()
	_texto_charleston.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja_izquierda.add_child(_texto_charleston)
	_zona_descartes = ScrollContainer.new()
	_zona_descartes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja_izquierda.add_child(_zona_descartes)
	_fichas_descartadas = HFlowContainer.new()
	_fichas_descartadas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zona_descartes.add_child(_fichas_descartadas)

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

	# --- Botones de acción (grandes, para dedos). Cada fase muestra los suyos. ---
	var acciones := HBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_CENTER
	acciones.add_theme_constant_override("separation", 16)
	columna.add_child(acciones)
	_boton_pasar = _boton("Pasar", pasar_fichas)
	_boton_segundo_si = _boton("Sí, otro Charleston", func(): decidir_segundo_charleston(true))
	_boton_segundo_no = _boton("No, seguir", func(): decidir_segundo_charleston(false))
	_boton_robar = _boton("Robar", robar)
	_boton_descartar = _boton("Descartar", descartar)
	_boton_sugerir = _boton("Sugerir", sugerir)
	for b in [_boton_pasar, _boton_segundo_si, _boton_segundo_no, _boton_robar, _boton_descartar, _boton_sugerir]:
		acciones.add_child(b)
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
