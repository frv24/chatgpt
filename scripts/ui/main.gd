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

enum Fase { CHARLESTON, TURNO_RIVAL, ROBAR, DESCARTAR, DECIDIR_CANTO, FIN }

const COLOR_FONDO := Color("0f5132")  # verde tapete
const ARCHIVO_PROGRESO := "user://progreso.cfg"
const ABREVIATURAS := ["Tú", "Der", "Enf", "Izq"]

## Segundos que tarda cada rival en jugar su turno (para que se vea qué hace).
## Lo decide el nivel; `pausa_forzada` (si es >= 0) lo sustituye (para pruebas).
var pausa_rivales := 1.2
var pausa_forzada := -1.0

## Nivel actual (ver scripts/logica/niveles.gd) y si ya se eligió alguna vez.
var nivel_id := "facil"
var _nivel: Dictionary = Niveles.obtener("facil")
var _nivel_elegido := false
## Sugerencias que quedan en esta partida (-1 = sin límite).
var _sugerencias_restantes := -1
## Puntos acumulados de cada jugador (niveles con marcador) y pagos de la última partida.
var marcador := [0, 0, 0, 0]
var _ultimos_pagos := [0, 0, 0, 0]

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
## Mientras decides si cantar un descarte: {"rivales": cantos de los rivales, "mio": evaluación}.
var _canto_pendiente: Dictionary = {}

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
var _titulo_tarjeta: Label
var _mensaje: Label
var _info_partida: Label
var _boton_marcador: Button
var _boton_robar: Button
var _boton_descartar: Button
var _boton_pasar: Button
var _boton_sugerir: Button
var _boton_segundo_si: Button
var _boton_segundo_no: Button
var _boton_mahjong: Button
var _boton_no_cantar: Button
var _boton_cambiar_comodin: Button
var _fila_expuestas: HBoxContainer
var _expuestas_rivales: VBoxContainer
var _timer_rivales: Timer
var _capa_leccion: Control
var _leccion: Dictionary  # etiquetas de la ventana de lección
var _boton_entendido: Button
var _capa_reglas: Control
var _ventana_tarjeta: VentanaTarjeta
var _capa_niveles: Control
var _capa_marcador: Control
var _texto_marcador: Label
var _botones_cantar := {}  # tamaño del grupo (3, 4, 5) -> botón
var _reglas: Dictionary  # etiquetas de la ventana de reglas
var _analisis_lista: Array[Dictionary] = []


func _ready() -> void:
	_cargar_progreso()
	_crear_interfaz()
	nueva_partida()
	if not _nivel_elegido:
		_abrir_niveles()


# =============================================================================
#  INICIO Y CHARLESTON
# =============================================================================

func nueva_partida() -> void:
	_timer_rivales.stop()
	_nivel = Niveles.obtener(nivel_id)
	pausa_rivales = pausa_forzada if pausa_forzada >= 0 else _nivel["pausa"]
	_sugerencias_restantes = _nivel["sugerencias"]
	partida = Partida.new(manos_tarjeta, _proximo_este, 0, _nivel["rivales"])
	_proximo_este = (_proximo_este + 1) % 4
	charleston = partida.crear_charleston()
	mano = partida.manos[0]
	objetivo_elegido = false
	segundo_saltado = false
	seleccion.clear()
	ids_nuevas.clear()
	_ordenar_mano()
	fase = Fase.CHARLESTON
	_mostrar_mensaje("Nivel %s. Eres %s. Empieza el Charleston: mira la tarjeta, elige tu mano objetivo y toca 3 fichas que no te sirvan." % [
		_nivel["nombre"], partida.viento(0)])
	_refrescar()
	for clave in ["preparar_mesa", "las_fichas", "asientos", "charleston", "charleston_direcciones"]:
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
	if _hay_ventana_abierta():
		_timer_rivales.start(pausa_rivales)
		return
	var r := partida.jugar_turno_rival()
	var texto := ""
	if r["cambios"] > 0:
		texto = "%s cambió una ficha por un comodín expuesto. " % partida.nombre(r["jugador"])
		mostrar_leccion("cambiar_comodin")
	if r["descartada"] == null:
		_mostrar_mensaje(texto)
		_siguiente_turno()
		return
	_mostrar_mensaje(texto + "%s descartó: %s." % [partida.nombre(r["jugador"]), r["descartada"].nombre()])
	if partida.descartes.size() >= 3:
		mostrar_leccion("descartes_rivales")
	_tras_descarte()


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
	if not partida.cambios_de_comodin(0).is_empty():
		_agregar_mensaje("¡Puedes cambiar una ficha por un comodín expuesto!")
		mostrar_leccion("cambiar_comodin")
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
	_tras_descarte()


## En tu turno (antes de descartar), cambia tu ficha por un comodín de un grupo expuesto.
func cambiar_comodin() -> void:
	var opciones := partida.cambios_de_comodin(0)
	if fase != Fase.DESCARTAR or opciones.is_empty():
		return
	var opcion: Dictionary = opciones[0]
	var comodin := partida.cambiar_comodin(0, opcion)
	ids_nuevas.clear()
	ids_nuevas.append(comodin.id)
	seleccion.clear()
	var de_quien := "tu grupo" if opcion["dueno"] == 0 else "el grupo de " + partida.nombre(opcion["dueno"])
	_mostrar_mensaje("Pusiste tu %s en %s y te llevaste el comodín." % [opcion["ficha"].nombre(), de_quien])
	if partida.comprobar_mahjong():
		_terminar()
		return
	_agregar_mensaje("Ahora descarta una ficha.")
	_refrescar()


# =============================================================================
#  CANTAR DESCARTES
# =============================================================================

## Después de cada descarte: ¿alguien quiere la ficha?
func _tras_descarte() -> void:
	var ultimo: Dictionary = partida.descartes.back()
	var ficha: Ficha = ultimo["ficha"]
	var cantos_rivales := partida.cantos_de_rivales()
	# Qué puedes hacer tú con esa ficha. Según el nivel, te avisamos solo si te
	# conviene (Fácil, Normal, Intermedio) o siempre que las reglas lo permitan (Experto).
	var mio := {"mahjong": false, "opciones": []}
	var ev := {}
	if ultimo["jugador"] != 0:
		ev = partida.evaluar_canto(0, ficha)
		mio["mahjong"] = ev["mahjong"]
		if _nivel["cantos"] == "todos":
			mio["opciones"] = partida.grupos_posibles(0, ficha)
		elif ev["cant"] > 0:
			mio["opciones"] = [ev["cant"]]
	if not mio["mahjong"] and mio["opciones"].is_empty():
		_resolver_cantos(cantos_rivales, false)
		return

	# Te preguntamos (los rivales esperan tu decisión).
	_canto_pendiente = {"rivales": cantos_rivales, "mio": mio}
	fase = Fase.DECIDIR_CANTO
	if mio["mahjong"] and _nivel["cantos"] != "todos":
		_agregar_mensaje("¡Con esa ficha completas tu mano! Pulsa «¡Mahjong!».")
	elif _nivel["cantos"] == "explicados":
		_agregar_mensaje("¡Puedes cantarla! Formarías un %s de %s y a «%s» le faltarían %d en vez de %d." % [
			Partida.NOMBRE_GRUPO[ev["cant"]], ficha.nombre(), ev["mano"], ev["faltan_despues"], ev["faltan_antes"]])
	else:
		_agregar_mensaje("Puedes cantar %s. ¿Qué haces?" % ficha.nombre())
	mostrar_leccion("cantar")
	_refrescar()


## Tu respuesta: "mahjong", "exponer" (con el tamaño del grupo) o "pasar".
func decidir_canto(respuesta: String, cant: int = 0) -> void:
	if fase != Fase.DECIDIR_CANTO:
		return
	var cantos: Array[Dictionary] = _canto_pendiente["rivales"].duplicate()
	var mio: Dictionary = _canto_pendiente["mio"]
	if respuesta == "exponer" and cant == 0 and not mio["opciones"].is_empty():
		cant = mio["opciones"][0]
	if respuesta == "mahjong" and mio["mahjong"]:
		cantos.append({"jugador": 0, "mahjong": true, "cant": 0})
	elif respuesta == "exponer" and cant in mio["opciones"]:
		cantos.append({"jugador": 0, "mahjong": false, "cant": cant})
	_canto_pendiente = {}
	_mostrar_mensaje("")
	_resolver_cantos(cantos, respuesta != "pasar")


## Decide quién se queda el descarte (si alguien lo quiere) y sigue la partida.
func _resolver_cantos(cantos: Array[Dictionary], yo_la_queria: bool) -> void:
	var elegido := partida.elegir_canto(cantos)
	if elegido.is_empty():
		_siguiente_turno()
		return
	var jugador: int = elegido["jugador"]
	var ficha := partida.cantar(jugador, elegido["cant"], elegido["mahjong"])
	seleccion.clear()
	ids_nuevas.clear()
	if yo_la_queria and jugador != 0:
		_agregar_mensaje("%s también la quería y tenía preferencia (%s)." % [
			partida.nombre(jugador), "hacía Mahjong" if elegido["mahjong"] else "está antes en el turno"])
	if partida.terminada:
		_terminar()
		return

	var grupo: String = Partida.NOMBRE_GRUPO[elegido["cant"]]
	if jugador == 0:
		ids_nuevas.append(ficha.id)
		fase = Fase.DESCARTAR
		_agregar_mensaje("Cantaste %s: expones un %s. Ahora descarta una ficha (sin robar)." % [ficha.nombre(), grupo])
		if partida.mejor_analisis(0)["faltan"] == Validador.IMPOSIBLE:
			_agregar_mensaje("Cuidado: con tus grupos expuestos ya no encajas en ninguna mano de la tarjeta (mano muerta).")
		mostrar_leccion("exponer")
		mostrar_leccion("manos_ocultas")
		_refrescar()
	else:
		_agregar_mensaje("%s cantó %s y expone un %s." % [partida.nombre(jugador), ficha.nombre(), grupo])
		mostrar_leccion("exponer")
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
	if _nivel["marcador"]:
		_anotar_pagos()
	mostrar_leccion("niveles")
	_refrescar()


## Suma los pagos de la partida al marcador (solo en niveles con marcador).
func _anotar_pagos() -> void:
	var r := partida.calcular_pagos()
	_ultimos_pagos = r["pagos"]
	for j in 4:
		marcador[j] += _ultimos_pagos[j]
	_guardar_progreso()
	if partida.ganador == -1:
		_agregar_mensaje("Nadie paga.")
		return
	var extra := " (¡sin comodines, doble!)" if r["sin_comodines"] else ""
	var forma := "robando del muro: todos pagan doble" if partida.mahjong_con_descarte_de == -1 \
		else "con el descarte de %s, que paga doble" % partida.nombre(partida.mahjong_con_descarte_de)
	_agregar_mensaje("Vale %d%s; ganó %s. Tu resultado: %+d." % [r["valor"], extra, forma, _ultimos_pagos[0]])
	mostrar_leccion("puntuacion")


## Selecciona las fichas que el asesor recomienda soltar y explica por qué.
func sugerir() -> void:
	if _sugerencias_restantes == 0:
		_mostrar_mensaje("No te quedan sugerencias en esta partida (nivel %s)." % _nivel["nombre"])
		return
	if _sugerencias_restantes > 0:
		_sugerencias_restantes -= 1
	var cantidad := 1 if fase == Fase.DESCARTAR else Charleston.FICHAS_POR_PASE
	var sugeridas := Asesor.fichas_que_sobran(mano, manos_tarjeta, cantidad, partida.expuestas[0])
	seleccion.clear()
	for f in sugeridas:
		seleccion.append(f.id)
	var boton := "«Descartar»" if fase == Fase.DESCARTAR else "«Pasar»"
	_mostrar_mensaje("%s Pulsa %s si estás de acuerdo." % [
		Asesor.explicar(sugeridas, mano, manos_tarjeta, partida.expuestas[0]), boton])
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
	if not forzar and (not _nivel["explicaciones"] or _lecciones_vistas.has(clave)):
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
		Fase.DECIDIR_CANTO:
			return "cantar"
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
		nivel_id = config.get_value("partida", "nivel", "facil")
		_nivel_elegido = config.has_section_key("partida", "nivel")
		marcador = config.get_value("partida", "marcador", [0, 0, 0, 0])
	_nivel = Niveles.obtener(nivel_id)


func _guardar_progreso() -> void:
	var config := ConfigFile.new()
	config.set_value("lecciones", "vistas", _lecciones_vistas.keys())
	if _nivel_elegido:
		config.set_value("partida", "nivel", nivel_id)
	config.set_value("partida", "marcador", marcador)
	config.save(ARCHIVO_PROGRESO)


# =============================================================================
#  NIVELES Y MARCADOR
# =============================================================================

func _hay_ventana_abierta() -> bool:
	return _capa_leccion.visible or _capa_reglas.visible or _ventana_tarjeta.visible \
		or _capa_niveles.visible or _capa_marcador.visible


func _abrir_niveles() -> void:
	# Marca el nivel actual.
	for id in Niveles.ORDEN:
		var tarjeta: Button = _capa_niveles.find_child("nivel_" + id, true, false)
		var estilo: StyleBoxFlat = tarjeta.get_theme_stylebox("normal")
		estilo.border_color = Color("ffe082") if id == nivel_id else Color("2e7d57")
	_capa_niveles.visible = true


func elegir_nivel(id: String) -> void:
	nivel_id = id
	_nivel_elegido = true
	_capa_niveles.visible = false
	_guardar_progreso()
	nueva_partida()


func _abrir_marcador() -> void:
	var lineas: Array[String] = []
	for j in 4:
		var ultima := "   (última partida: %+d)" % _ultimos_pagos[j] if _ultimos_pagos[j] != 0 else ""
		lineas.append("%s:   %+d puntos%s" % [partida.nombre(j), marcador[j], ultima])
	_texto_marcador.text = "\n".join(lineas)
	_capa_marcador.visible = true


func reiniciar_marcador() -> void:
	marcador = [0, 0, 0, 0]
	_ultimos_pagos = [0, 0, 0, 0]
	_guardar_progreso()
	_abrir_marcador()


## Ventana para elegir el nivel al empezar una partida.
func _crear_ventana_niveles() -> void:
	_capa_niveles = _capa_oscura()
	var tarjeta := _panel_flotante(Vector2(1160, 0))
	_capa_niveles.add_child(tarjeta)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 18)
	tarjeta.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Nueva partida: elige tu nivel"
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color("ffe082"))
	caja.add_child(titulo)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	caja.add_child(fila)
	for id in Niveles.ORDEN:
		var n := Niveles.obtener(id)
		var boton := Button.new()
		boton.name = "nivel_" + id
		boton.custom_minimum_size = Vector2(265, 250)
		boton.pressed.connect(func(): elegir_nivel(id))
		for estado in ["normal", "hover", "pressed", "focus"]:
			var estilo := StyleBoxFlat.new()
			estilo.bg_color = Color("1f5c40") if estado == "hover" else Color("184a33")
			estilo.set_border_width_all(3)
			estilo.border_color = Color("2e7d57")
			estilo.set_corner_radius_all(12)
			boton.add_theme_stylebox_override(estado, estilo)
		var textos := VBoxContainer.new()
		textos.set_anchors_preset(Control.PRESET_FULL_RECT)
		textos.offset_left = 16
		textos.offset_right = -16
		textos.offset_top = 14
		textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.add_child(textos)
		var nombre := Label.new()
		nombre.text = n["nombre"]
		nombre.add_theme_font_size_override("font_size", 28)
		nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		textos.add_child(nombre)
		var descripcion := Label.new()
		descripcion.text = n["descripcion"]
		descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		descripcion.add_theme_font_size_override("font_size", 17)
		descripcion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		textos.add_child(descripcion)
		fila.add_child(boton)

	var pie := HBoxContainer.new()
	caja.add_child(pie)
	var nota := Label.new()
	nota.text = "Los puntos y el marcador solo se usan en Intermedio y Experto."
	nota.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(nota)
	pie.add_child(_boton("Cancelar", func(): _capa_niveles.visible = false))


## Ventana del marcador (niveles Intermedio y Experto).
func _crear_ventana_marcador() -> void:
	_capa_marcador = _capa_oscura()
	var tarjeta := _panel_flotante(Vector2(640, 0))
	_capa_marcador.add_child(tarjeta)
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	tarjeta.add_child(caja)
	var titulo := Label.new()
	titulo.text = "Marcador"
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color("ffe082"))
	caja.add_child(titulo)
	_texto_marcador = Label.new()
	_texto_marcador.add_theme_font_size_override("font_size", 22)
	caja.add_child(_texto_marcador)
	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_END
	botones.add_theme_constant_override("separation", 12)
	caja.add_child(botones)
	botones.add_child(_boton("Poner a cero", reiniciar_marcador, 170))
	botones.add_child(_boton("¿Cómo se cuenta?", func(): mostrar_leccion("puntuacion", true), 200))
	botones.add_child(_boton("Cerrar", func(): _capa_marcador.visible = false, 130))


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
	elif fase == Fase.DECIDIR_CANTO:
		_mostrar_mensaje("Primero decide si cantas el descarte o no.")
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


## Abre la «Tarjeta 2026» completa.
func _abrir_tarjeta() -> void:
	_ventana_tarjeta.abrir(_analisis_lista, objetivo["nombre"], _nivel["consejos"])


func _al_elegir_mano_en_tarjeta(nombre: String) -> void:
	for m in manos_tarjeta:
		if m["nombre"] == nombre:
			objetivo = m
			objetivo_elegido = true
	_mostrar_mensaje("Tu objetivo ahora es «%s»." % nombre)
	_refrescar()


func _al_elegir_objetivo(indice: int) -> void:
	objetivo = _analisis_lista[indice]["mano"]
	objetivo_elegido = true
	_refrescar()


# =============================================================================
#  DIBUJAR EL ESTADO EN PANTALLA
# =============================================================================

func _refrescar() -> void:
	_info_partida.text = "Nivel: %s · Eres: %s · Muro: %d" % [_nivel["nombre"], partida.viento(0), partida.mazo.quedan()]
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
	var decidiendo := fase == Fase.DECIDIR_CANTO
	_boton_mahjong.visible = decidiendo and _canto_pendiente["mio"]["mahjong"]
	for cant in _botones_cantar:
		_botones_cantar[cant].visible = decidiendo and cant in _canto_pendiente["mio"]["opciones"]
	_boton_no_cantar.visible = decidiendo
	_boton_robar.visible = not en_charleston and not decidiendo
	_boton_descartar.visible = not en_charleston and not decidiendo
	_boton_robar.disabled = fase != Fase.ROBAR
	_boton_descartar.disabled = fase != Fase.DESCARTAR
	_boton_cambiar_comodin.visible = fase == Fase.DESCARTAR and not partida.cambios_de_comodin(0).is_empty()
	_boton_sugerir.visible = _nivel["sugerencias"] != 0
	_boton_sugerir.text = "Sugerir" if _sugerencias_restantes < 0 else "Sugerir (%d)" % _sugerencias_restantes
	_boton_sugerir.disabled = not (_pasando_fichas() or fase == Fase.DESCARTAR) or _sugerencias_restantes == 0
	_boton_marcador.visible = _nivel["marcador"]


func _refrescar_tarjeta() -> void:
	# Con consejos, las manos se ordenan de la más cercana a la más lejana y el objetivo
	# se elige solo. Sin consejos (Intermedio y Experto) van en el orden de la tarjeta:
	# decidir a qué mano jugar es parte del juego.
	_analisis_lista = Validador.manos_mas_cercanas(mano, manos_tarjeta, manos_tarjeta.size(), partida.expuestas[0])
	if not _nivel["consejos"]:
		var por_nombre := {}
		for a in _analisis_lista:
			por_nombre[a["mano"]["nombre"]] = a
		_analisis_lista.clear()
		for m in manos_tarjeta:
			_analisis_lista.append(por_nombre[m["nombre"]])
	_titulo_tarjeta.text = ("Tus manos más cercanas" if _nivel["consejos"] else "Tarjeta 2026") \
		+ " (toca una para elegirla como objetivo)"
	if not objetivo_elegido:
		objetivo = _analisis_lista[0]["mano"]

	_lista_tarjeta.clear()
	for i in _analisis_lista.size():
		var a := _analisis_lista[i]
		var texto := "%s   %s" % [a["mano"]["nombre"], a["mano"]["patron"]]
		if a["mano"]["oculta"]:
			texto += "   (oculta)"
		if a["faltan"] == Validador.IMPOSIBLE:
			texto = "No posible · " + texto
		elif _nivel["consejos"]:
			texto = "Faltan %d · %s" % [a["faltan"], texto]
		_lista_tarjeta.add_item(texto)
		if a["mano"]["nombre"] == objetivo["nombre"]:
			_lista_tarjeta.select(i)

	var texto_objetivo := "Objetivo: %s\n%s" % [objetivo["nombre"], objetivo["explicacion"]]
	if not objetivo_elegido and not _nivel["consejos"]:
		texto_objetivo = "Todavía no has elegido objetivo: toca una mano de la tarjeta."
		_lista_tarjeta.deselect_all()
	if _nivel["consejos"]:
		texto_objetivo += "\n\nConsejo: " + objetivo["consejo"]
	_texto_objetivo.text = texto_objetivo


func _refrescar_mano() -> void:
	for hijo in _fila_mano.get_children():
		hijo.queue_free()

	var consejos: bool = _nivel["consejos"]
	var ids_utiles: Array[int] = []
	if consejos:
		ids_utiles = Validador.ids_utiles(mano, Validador.analizar(mano, objetivo, partida.expuestas[0]))

	for ficha in mano:
		var fv := FichaVisual.new(ficha)
		fv.mostrar_consejo = consejos
		fv.util = ficha.id in ids_utiles
		fv.nueva = ficha.id in ids_nuevas
		fv.seleccionada = ficha.id in seleccion
		fv.tocada.connect(_al_tocar_ficha)
		fv.soltada_encima.connect(_al_soltar_ficha)
		_fila_mano.add_child(fv)

	# Tus grupos expuestos, encima de la mano.
	for hijo in _fila_expuestas.get_children():
		hijo.queue_free()
	_fila_expuestas.visible = not partida.expuestas[0].is_empty()
	if _fila_expuestas.visible:
		var etiqueta := Label.new()
		etiqueta.text = "Tus grupos expuestos:"
		_fila_expuestas.add_child(etiqueta)
		for g in partida.expuestas[0]:
			_fila_expuestas.add_child(_grupo_pequeno(g))


## El panel de la izquierda muestra los pasos del Charleston o, al jugar, los descartes.
func _refrescar_panel_izquierdo() -> void:
	var en_charleston := fase == Fase.CHARLESTON
	_texto_charleston.visible = en_charleston
	_zona_descartes.visible = not en_charleston
	_expuestas_rivales.visible = not en_charleston
	if en_charleston:
		_titulo_izquierda.text = "Charleston: intercambio de fichas"
		_texto_charleston.text = _texto_pasos_charleston()
		return

	# Grupos expuestos de los rivales (una fila por rival que tenga alguno).
	for hijo in _expuestas_rivales.get_children():
		hijo.queue_free()
	for j in range(1, 4):
		if partida.expuestas[j].is_empty():
			continue
		var fila := HBoxContainer.new()
		var nombre := Label.new()
		nombre.text = partida.nombre(j) + ":"
		nombre.custom_minimum_size.x = 150
		fila.add_child(nombre)
		for g in partida.expuestas[j]:
			fila.add_child(_grupo_pequeno(g))
		_expuestas_rivales.add_child(fila)

	for hijo in _fichas_descartadas.get_children():
		hijo.queue_free()
	if fase == Fase.FIN and partida.ganador > 0:
		# Enseña la mano del rival que ganó: así se aprende cómo es una mano completa.
		_titulo_izquierda.text = "Mano ganadora de %s: «%s»" % [
			partida.nombre(partida.ganador), partida.mano_ganadora["nombre"]]
		var ganadora: Array[Ficha] = partida.manos[partida.ganador].duplicate()
		for g in partida.expuestas[partida.ganador]:
			ganadora.append_array(g["fichas"])
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


## Un grupo expuesto: sus fichas juntas y en pequeño.
func _grupo_pequeno(grupo: Dictionary) -> Control:
	var escala := 0.6
	var caja := HBoxContainer.new()
	caja.add_theme_constant_override("separation", 0)
	for ficha in grupo["fichas"]:
		var fv := FichaVisual.new(ficha)
		fv.scale = Vector2(escala, escala)
		fv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hueco := Control.new()
		hueco.custom_minimum_size = FichaVisual.TAMANO * escala
		hueco.add_child(fv)
		caja.add_child(hueco)
	# Un pequeño espacio entre grupos.
	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_right", 10)
	margen.add_child(caja)
	return margen


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
	lineas.append("Truco: elige tu mano objetivo en la tarjeta y pasa lo que no encaje%s." % (
		" (lo apagado)" if _nivel["consejos"] else ""))
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
	_boton_marcador = _boton("Marcador", _abrir_marcador, 130)
	barra.add_child(_boton_marcador)
	barra.add_child(_boton("Tarjeta 2026", _abrir_tarjeta, 150))
	barra.add_child(_boton("Reglas", _abrir_reglas, 110))
	barra.add_child(_boton("Nueva partida", _abrir_niveles, 160))

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
	_expuestas_rivales = VBoxContainer.new()
	caja_izquierda.add_child(_expuestas_rivales)
	_zona_descartes = ScrollContainer.new()
	_zona_descartes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caja_izquierda.add_child(_zona_descartes)
	_fichas_descartadas = HFlowContainer.new()
	_fichas_descartadas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zona_descartes.add_child(_fichas_descartadas)

	var panel_tarjeta := _panel("")
	_titulo_tarjeta = panel_tarjeta.get_child(0).get_child(0) as Label
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
	_fila_expuestas = HBoxContainer.new()
	_fila_expuestas.alignment = BoxContainer.ALIGNMENT_CENTER
	_fila_expuestas.visible = false
	columna.add_child(_fila_expuestas)
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
	_boton_mahjong = _boton("¡Mahjong!", func(): decidir_canto("mahjong"))
	for cant in [3, 4, 5]:
		_botones_cantar[cant] = _boton("Cantar " + Partida.NOMBRE_GRUPO[cant], func(): decidir_canto("exponer", cant))
	_boton_no_cantar = _boton("No cantar", func(): decidir_canto("pasar"))
	_boton_cambiar_comodin = _boton("Cambiar comodín", cambiar_comodin, 190)
	for b in [_boton_pasar, _boton_segundo_si, _boton_segundo_no, _boton_mahjong] + _botones_cantar.values() + [
			_boton_no_cantar, _boton_robar, _boton_descartar, _boton_cambiar_comodin, _boton_sugerir]:
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
	_ventana_tarjeta = VentanaTarjeta.new()
	_ventana_tarjeta.mano_elegida.connect(_al_elegir_mano_en_tarjeta)
	add_child(_ventana_tarjeta)
	_crear_ventana_marcador()
	_crear_ventana_niveles()


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
