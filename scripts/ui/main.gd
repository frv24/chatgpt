extends Control
## Pantalla principal: partida de aprendizaje contra 3 rivales de la máquina.
##
## Cómo se juega:
##   1. Se reparten 13 fichas a cada jugador (14 al Este).
##   2. CHARLESTON: intercambio de fichas para mejorar la mano.
##   3. Turnos hacia la derecha: robar 1 ficha y descartar 1.
##   4. Gana quien complete una mano de la tarjeta.
##
## Las LECCIONES (el "¿por qué?" de cada regla) salen solas la primera vez
## y siempre se pueden volver a leer con «¿Por qué?» o «Reglas».
##
## Toda la interfaz se crea desde código para que puedas leerla de arriba abajo.

enum Fase { CHARLESTON, TURNO_RIVAL, ROBAR, DESCARTAR, FIN }

const COLOR_FONDO := Color("0f5132")  # verde tapete
const ARCHIVO_PROGRESO := "user://progreso.cfg"
const ABREVIATURAS := ["Tú", "Der", "Enf", "Izq"]

## Segundos que tarda cada rival en jugar su turno (para que se vea qué hace).
var pausa_rivales := 1.2

var partida: Partida
var charleston: Charleston
var mano: Array[Ficha] = []
var fase := Fase.CHARLESTON
var manos_tarjeta := Tarjeta.manos()
## Quién será el Este en la próxima partida (rota hacia la derecha).
var _proximo_este := 0
var segundo_saltado := false

## Mano de la tarjeta que el jugador intenta conseguir (para los consejos).
var objetivo: Dictionary = {}
var objetivo_elegido := false
## Ids de las fichas seleccionadas (1 para descartar, hasta 3 en el Charleston).
var seleccion: Array[int] = []
## Ids de las fichas recién recibidas o robadas (se pintan en amarillo).
var ids_nuevas: Array[int] = []

# Lecciones
var _cola_lecciones: Array[String] = []
var _lecciones_vistas := {}

# Nodos de la interfaz (se crean en _crear_interfaz).
var _fila_mano: HBoxContainer
var _titulo_izquierda: Label
var _zona_descartes: ScrollContainer
var _fichas_descartadas: HFlowContainer
var _texto_charleston: Label
var _lista_tarjeta: ItemList
var _texto_objetivo: Label
var _mensaje: Label
var _info_partida: Label
var _interruptor_consejos: CheckButton
var _interruptor_explicaciones: CheckButton
var _boton_robar: Button
var _boton_descartar: Button
var _boton_pasar: Button
var _boton_sugerir: Button
var _boton_segundo_si: Button
var _boton_segundo_no: Button
var _timer_rivales: Timer
var _capa_leccion: Control
var _leccion: Dictionary  # etiquetas de la ventana de lección
var _boton_entendido: Button
var _capa_reglas: Control
var _reglas: Dictionary  # etiquetas de la ventana de reglas
var _analisis_lista: Array[Dictionary] = []


func _ready() -> void:
	_cargar_progreso()
	_crear_interfaz()
	nueva_partida()


# =============================================================================
#  INICIO Y CHARLESTON
# =============================================================================

func nueva_partida() -> void:
	_timer_rivales.stop()
	partida = Partida.new(manos_tarjeta, _proximo_este)
	_proximo_este = (_proximo_este + 1) % 4
	charleston = partida.crear_charleston()
	mano = partida.manos[0]
	objetivo_elegido = false
	segundo_saltado = false
	seleccion.clear()
	ids_nuevas.clear()
	_ordenar_mano()
	fase = Fase.CHARLESTON
	_mostrar_mensaje("Eres %s. Empieza el Charleston: mira la tarjeta, elige tu mano objetivo y toca 3 fichas que no te sirvan." % partida.viento(0))
	_refrescar()
	for clave in ["preparar_mesa", "asientos", "charleston", "charleston_direcciones"]:
		mostrar_leccion(clave)


func pasar_fichas() -> void:
	if not _pasando_fichas():
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
		_mostrar_mensaje(texto + " ¡Charleston terminado!")
		_empezar_turnos()
		return
	var descripcion := charleston.descripcion()
	_mostrar_mensaje(texto + " " + descripcion + ("" if descripcion.ends_with("?") else "."))
	_refrescar()
	# Lecciones de los momentos importantes del Charleston.
	match charleston.etapa:
		Charleston.Etapa.PRIMERO:
			if charleston.indice_pase == 2:
				mostrar_leccion("ultimo_pase")
		Charleston.Etapa.PREGUNTA_SEGUNDO:
			mostrar_leccion("segundo_charleston")
		Charleston.Etapa.CORTESIA:
			mostrar_leccion("cortesia")


# =============================================================================
#  TURNOS
# =============================================================================

func _empezar_turnos() -> void:
	mostrar_leccion("turnos")
	_siguiente_turno()


## Decide qué pasa ahora según a quién le toque.
func _siguiente_turno() -> void:
	if partida.terminada:
		_terminar()
		return
	if partida.turno == 0:
		if partida.debe_robar():
			fase = Fase.ROBAR
			_agregar_mensaje("Tu turno: pulsa «Robar».")
		elif partida.comprobar_mahjong():
			_terminar()
			return
		else:
			fase = Fase.DESCARTAR
			_agregar_mensaje("Eres el Este: empiezas DESCARTANDO sin robar (ya tienes 14 fichas).")
	else:
		fase = Fase.TURNO_RIVAL
		_agregar_mensaje("Turno de %s…" % partida.nombre(partida.turno))
		_timer_rivales.start(pausa_rivales)
	_refrescar()


func _al_terminar_timer_rivales() -> void:
	# Si el jugador está leyendo una lección, esperamos a que la cierre.
	if _capa_leccion.visible or _capa_reglas.visible:
		_timer_rivales.start(pausa_rivales)
		return
	var r := partida.jugar_turno_rival()
	if r["descartada"] != null:
		_mostrar_mensaje("%s descartó: %s." % [partida.nombre(r["jugador"]), r["descartada"].nombre()])
		if partida.descartes.size() >= 3:
			mostrar_leccion("descartes_rivales")
	_siguiente_turno()


func robar() -> void:
	if fase != Fase.ROBAR:
		return
	var nueva := partida.robar()
	if nueva == null or partida.terminada:
		_terminar()
		return
	ids_nuevas.clear()
	ids_nuevas.append(nueva.id)
	fase = Fase.DESCARTAR
	_mostrar_mensaje("Has robado: %s. Toca la ficha que quieras descartar y pulsa «Descartar»." % nueva.nombre())
	_refrescar()


func descartar() -> void:
	if fase != Fase.DESCARTAR:
		return
	var elegidas := _fichas_seleccionadas()
	if elegidas.is_empty():
		_mostrar_mensaje("Primero toca una ficha para seleccionarla.")
		return
	var ficha := elegidas[0]
	partida.descartar(ficha)
	seleccion.clear()
	ids_nuevas.clear()
	var aviso := " Cuidado: ¡los comodines casi nunca se descartan!" if ficha.es_comodin() else ""
	_mostrar_mensaje("Descartaste: %s.%s" % [ficha.nombre(), aviso])
	_siguiente_turno()


func _terminar() -> void:
	fase = Fase.FIN
	_timer_rivales.stop()
	if partida.ganador == -1:
		_mostrar_mensaje("Se acabó el muro y nadie hizo Mahjong: ¡empate! Pulsa «Nueva partida».")
		mostrar_leccion("muro_vacio")
	elif partida.ganador == 0:
		_mostrar_mensaje("¡MAHJONG! Completaste «%s» (%d puntos)." % [
			partida.mano_ganadora["nombre"], partida.mano_ganadora["puntos"]])
		mostrar_leccion("mahjong")
	else:
		_mostrar_mensaje("%s hizo ¡MAHJONG! con «%s». Mira su mano a la izquierda. Pulsa «Nueva partida»." % [
			partida.nombre(partida.ganador), partida.mano_ganadora["nombre"]])
		mostrar_leccion("mahjong")
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
#  LECCIONES ("¿por qué?")
# =============================================================================

## Muestra una lección. Si `forzar` es false, solo sale la primera vez
## y solo si el interruptor «Explicaciones» está activado.
func mostrar_leccion(clave: String, forzar: bool = false) -> void:
	if not forzar and (not _interruptor_explicaciones.button_pressed or _lecciones_vistas.has(clave)):
		return
	if clave in _cola_lecciones:
		return
	_cola_lecciones.append(clave)
	if not _capa_leccion.visible:
		_mostrar_siguiente_leccion()


func _mostrar_siguiente_leccion() -> void:
	if _cola_lecciones.is_empty():
		_capa_leccion.visible = false
		return
	var clave: String = _cola_lecciones.pop_front()
	_rellenar_leccion(_leccion, Lecciones.obtener(clave))
	_boton_entendido.text = "Siguiente" if not _cola_lecciones.is_empty() else "¡Entendido!"
	_capa_leccion.visible = true
	_lecciones_vistas[clave] = true
	_guardar_progreso()


## La lección que explica lo que está pasando ahora mismo.
func _leccion_del_momento() -> String:
	match fase:
		Fase.CHARLESTON:
			match charleston.etapa:
				Charleston.Etapa.PRIMERO:
					return ["charleston", "charleston_direcciones", "ultimo_pase"][charleston.indice_pase]
				Charleston.Etapa.PREGUNTA_SEGUNDO:
					return "segundo_charleston"
				Charleston.Etapa.CORTESIA:
					return "cortesia"
			return "charleston_direcciones"
		Fase.FIN:
			return "muro_vacio" if partida.ganador == -1 else "mahjong"
	return "turnos"


func _rellenar_leccion(etiquetas: Dictionary, leccion: Dictionary) -> void:
	etiquetas["titulo"].text = leccion["titulo"]
	etiquetas["texto"].text = leccion["texto"]
	etiquetas["mesa"].text = leccion["mesa"]


func _al_elegir_regla(indice: int) -> void:
	_rellenar_leccion(_reglas, Lecciones.obtener(Lecciones.ORDEN[indice]))


func _abrir_reglas() -> void:
	_capa_reglas.visible = true
	_reglas["lista"].select(0)
	_al_elegir_regla(0)


func _cargar_progreso() -> void:
	var config := ConfigFile.new()
	if config.load(ARCHIVO_PROGRESO) == OK:
		for clave in config.get_value("lecciones", "vistas", []):
			_lecciones_vistas[clave] = true


func _guardar_progreso() -> void:
	var config := ConfigFile.new()
	config.set_value("lecciones", "vistas", _lecciones_vistas.keys())
	config.save(ARCHIVO_PROGRESO)


# =============================================================================
#  EVENTOS DE LA INTERFAZ
# =============================================================================

func _al_tocar_ficha(fv: FichaVisual) -> void:
	var id := fv.ficha.id
	if _pasando_fichas():
		if fv.ficha.es_comodin():
			_mostrar_mensaje("Los comodines no se pueden pasar en el Charleston. ¡Guárdalos, valen mucho!")
			mostrar_leccion("comodines_charleston")
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
	elif fase == Fase.TURNO_RIVAL:
		_mostrar_mensaje("Espera: es el turno de %s." % partida.nombre(partida.turno))
		return
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
	_info_partida.text = "Eres: %s · Muro: %d" % [partida.viento(0), partida.mazo.quedan()]
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

	for hijo in _fichas_descartadas.get_children():
		hijo.queue_free()
	if fase == Fase.FIN and partida.ganador > 0:
		# Enseña la mano del rival que ganó: así se aprende cómo es una mano completa.
		_titulo_izquierda.text = "Mano ganadora de %s: «%s»" % [
			partida.nombre(partida.ganador), partida.mano_ganadora["nombre"]]
		var ganadora: Array[Ficha] = partida.manos[partida.ganador].duplicate()
		ganadora.sort_custom(func(a: Ficha, b: Ficha): return a.orden() < b.orden())
		for ficha in ganadora:
			_fichas_descartadas.add_child(_ficha_pequena(ficha, ""))
		return

	if fase == Fase.FIN:
		_titulo_izquierda.text = "Descartes"
	else:
		_titulo_izquierda.text = "Descartes · Turno de: %s" % partida.nombre(partida.turno)
	for d in partida.descartes:
		_fichas_descartadas.add_child(_ficha_pequena(d["ficha"], ABREVIATURAS[d["jugador"]]))


## Una ficha a tamaño reducido, con una etiqueta debajo (quién la descartó).
func _ficha_pequena(ficha: Ficha, etiqueta: String) -> Control:
	var escala := 0.7
	var fv := FichaVisual.new(ficha)
	fv.scale = Vector2(escala, escala)
	fv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hueco := Control.new()
	hueco.custom_minimum_size = FichaVisual.TAMANO * escala + Vector2(0, 18)
	hueco.add_child(fv)
	var texto := Label.new()
	texto.text = etiqueta
	texto.add_theme_font_size_override("font_size", 12)
	texto.position = Vector2(0, FichaVisual.TAMANO.y * escala)
	texto.size.x = FichaVisual.TAMANO.x * escala
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hueco.add_child(texto)
	return hueco


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
	lineas.append("Truco: elige tu mano objetivo en la tarjeta y pasa lo que no encaje (lo apagado).")
	lineas.append("¿Dudas? Pulsa «¿Por qué?» para ver la explicación de este paso.")
	return "\n".join(lineas)


func _mostrar_mensaje(texto: String) -> void:
	_mensaje.text = texto


## Añade texto al mensaje actual (para no borrar lo que acaba de pasar).
func _agregar_mensaje(texto: String) -> void:
	_mensaje.text = (_mensaje.text + " " + texto).strip_edges()


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
	barra.add_theme_constant_override("separation", 12)
	columna.add_child(barra)
	var titulo := Label.new()
	titulo.text = "Mahjong Americano"
	titulo.add_theme_font_size_override("font_size", 26)
	barra.add_child(titulo)
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.add_child(espacio)
	_info_partida = Label.new()
	barra.add_child(_info_partida)
	_interruptor_consejos = CheckButton.new()
	_interruptor_consejos.text = "Consejos"
	_interruptor_consejos.button_pressed = true
	_interruptor_consejos.toggled.connect(func(_activo): _refrescar())
	barra.add_child(_interruptor_consejos)
	_interruptor_explicaciones = CheckButton.new()
	_interruptor_explicaciones.text = "Explicaciones"
	_interruptor_explicaciones.button_pressed = true
	_interruptor_explicaciones.tooltip_text = "Muestra el porqué de cada regla la primera vez que aparece"
	barra.add_child(_interruptor_explicaciones)
	barra.add_child(_boton("Reglas", _abrir_reglas, 120))
	barra.add_child(_boton("Nueva partida", nueva_partida, 160))

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
	acciones.add_child(_boton("¿Por qué?", func(): mostrar_leccion(_leccion_del_momento(), true)))

	# --- El reloj que marca el ritmo de los rivales ---
	_timer_rivales = Timer.new()
	_timer_rivales.one_shot = true
	_timer_rivales.timeout.connect(_al_terminar_timer_rivales)
	add_child(_timer_rivales)

	_crear_ventana_leccion()
	_crear_ventana_reglas()


## Ventana que aparece encima del juego con una lección.
func _crear_ventana_leccion() -> void:
	_capa_leccion = _capa_oscura()
	var tarjeta := _panel_flotante(Vector2(780, 0))
	_capa_leccion.add_child(tarjeta)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	tarjeta.add_child(caja)
	_leccion = _etiquetas_leccion(caja)
	_boton_entendido = _boton("¡Entendido!", _mostrar_siguiente_leccion)
	_boton_entendido.size_flags_horizontal = Control.SIZE_SHRINK_END
	caja.add_child(_boton_entendido)


## Ventana «Reglas»: todas las lecciones, para repasarlas cuando quieras.
func _crear_ventana_reglas() -> void:
	_capa_reglas = _capa_oscura()
	var tarjeta := _panel_flotante(Vector2(1100, 560))
	_capa_reglas.add_child(tarjeta)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 20)
	tarjeta.add_child(fila)

	var lista := ItemList.new()
	lista.custom_minimum_size.x = 360
	for clave in Lecciones.ORDEN:
		lista.add_item(Lecciones.obtener(clave)["titulo"])
	lista.item_selected.connect(_al_elegir_regla)
	fila.add_child(lista)

	var caja := VBoxContainer.new()
	caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caja.add_theme_constant_override("separation", 14)
	fila.add_child(caja)
	_reglas = _etiquetas_leccion(caja)
	_reglas["lista"] = lista
	var espacio := Control.new()
	espacio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja.add_child(espacio)
	var cerrar := _boton("Cerrar", func(): _capa_reglas.visible = false)
	cerrar.size_flags_horizontal = Control.SIZE_SHRINK_END
	caja.add_child(cerrar)


## Crea las etiquetas de una lección (título, texto y "En la mesa real").
func _etiquetas_leccion(caja: VBoxContainer) -> Dictionary:
	var titulo := Label.new()
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color("ffe082"))
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(titulo)

	var texto := Label.new()
	texto.add_theme_font_size_override("font_size", 20)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(texto)

	var recuadro := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0.08)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(12)
	recuadro.add_theme_stylebox_override("panel", estilo)
	caja.add_child(recuadro)
	var interior := VBoxContainer.new()
	recuadro.add_child(interior)
	var encabezado := Label.new()
	encabezado.text = "En la mesa real"
	encabezado.add_theme_font_size_override("font_size", 18)
	encabezado.add_theme_color_override("font_color", Color("a5d6a7"))
	interior.add_child(encabezado)
	var mesa := Label.new()
	mesa.add_theme_font_size_override("font_size", 18)
	mesa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interior.add_child(mesa)

	return {"titulo": titulo, "texto": texto, "mesa": mesa}


## Fondo oscuro que tapa el juego (y bloquea los toques) mientras hay una ventana abierta.
func _capa_oscura() -> Control:
	var capa := ColorRect.new()
	capa.color = Color(0, 0, 0, 0.6)
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_STOP
	capa.visible = false
	add_child(capa)
	return capa


## Un panel centrado en la pantalla.
func _panel_flotante(tamano: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("123d2a")
	estilo.border_color = Color("ffe082")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(14)
	estilo.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", estilo)
	panel.custom_minimum_size = tamano
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	return panel


## Crea un botón grande con texto y la función que ejecuta al pulsarlo.
func _boton(texto: String, accion: Callable, ancho: int = 160) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(ancho, 56)
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
