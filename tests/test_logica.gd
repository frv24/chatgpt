extends SceneTree
## Pruebas automáticas de la lógica del juego (sin gráficos).
##
## Cómo ejecutarlas desde la terminal, en la carpeta del proyecto:
##   godot --headless --import
##   godot --headless --script res://tests/test_logica.gd
##
## Si todo va bien, termina con "TODAS LAS PRUEBAS PASARON".

var _fallos := 0
var _pruebas := 0


func _init() -> void:
	probar_mazo()
	probar_tarjeta()
	probar_manos_ganadoras()
	probar_comodines()
	probar_consejos()
	probar_asesor()
	probar_charleston()
	probar_partida()
	probar_expuestas()
	probar_cantos()
	probar_cambio_de_comodin()
	probar_lecciones()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _pruebas)
	else:
		print("FALLARON %d de %d pruebas" % [_fallos, _pruebas])
	quit(1 if _fallos > 0 else 0)


func comprobar(condicion: bool, descripcion: String) -> void:
	_pruebas += 1
	if condicion:
		print("  ok   ", descripcion)
	else:
		_fallos += 1
		print("  FALLO ", descripcion)


## Crea fichas a partir de un texto. Ejemplo: "flor flor bam2 bam2 comodin vN dB".
func fichas(texto: String) -> Array[Ficha]:
	var resultado: Array[Ficha] = []
	var id := 1000
	for clave in texto.split(" ", false):
		var f: Ficha
		if clave == "flor":
			f = Ficha.new(Ficha.Tipo.FLOR, "", 0, id)
		elif clave == "comodin":
			f = Ficha.new(Ficha.Tipo.COMODIN, "", 0, id)
		elif clave.begins_with("v"):
			f = Ficha.new(Ficha.Tipo.VIENTO, clave.substr(1), 0, id)
		elif clave.begins_with("d"):
			f = Ficha.new(Ficha.Tipo.DRAGON, clave.substr(1), 0, id)
		else:
			f = Ficha.new(Ficha.Tipo.NUMERO, clave.substr(0, 3), int(clave.substr(3)), id)
		assert(f.clave() == clave, "Clave mal escrita en la prueba: " + clave)
		resultado.append(f)
		id += 1
	return resultado


func mano(nombre: String) -> Dictionary:
	for m in Tarjeta.manos():
		if m["nombre"] == nombre:
			return m
	push_error("No existe la mano " + nombre)
	return {}


func probar_mazo() -> void:
	print("Mazo:")
	var mazo := Mazo.new(12345)
	comprobar(mazo.quedan() == 152, "el mazo tiene 152 fichas")
	var c := Validador.contar(mazo.fichas)
	comprobar(c["comodines"] == 8, "hay 8 comodines")
	comprobar(c["conteo"]["flor"] == 8, "hay 8 flores")
	comprobar(c["conteo"]["bam5"] == 4, "hay 4 copias de Nopal 5")
	comprobar(c["conteo"]["dB"] == 4, "hay 4 dragones blancos")
	var ids := {}
	for f in mazo.fichas:
		ids[f.id] = true
	comprobar(ids.size() == 152, "cada ficha tiene un id distinto")

	mazo.barajar()
	var otro := Mazo.new(12345)
	otro.barajar()
	comprobar(mazo.fichas[0].id == otro.fichas[0].id, "la misma semilla baraja igual")
	var mano_inicial := mazo.repartir(13)
	comprobar(mano_inicial.size() == 13 and mazo.quedan() == 139, "repartir 13 deja 139 en el mazo")


func probar_tarjeta() -> void:
	print("Tarjeta:")
	var manos := Tarjeta.manos()
	comprobar(manos.size() >= 40, "la tarjeta tiene %d manos" % manos.size())
	var nombres := {}
	var mal_suma := []
	var mal_ejemplo := []
	var mal_seccion := []
	for m in manos:
		nombres[m["nombre"]] = true
		var total := 0
		for g in m["grupos"]:
			total += g["cant"]
		if total != 14:
			mal_suma.append(m["nombre"])
		if not m["seccion"] in Tarjeta.SECCIONES:
			mal_seccion.append(m["nombre"])
		# El ejemplo de la tarjeta debe ser una mano ganadora de verdad.
		var ejemplo: Array[Ficha] = []
		for grupo in Tarjeta.ejemplo(m):
			ejemplo.append_array(grupo)
		if not Validador.es_mano_ganadora(ejemplo, m) or Validador.contar(ejemplo)["comodines"] > 8:
			mal_ejemplo.append(m["nombre"])
	comprobar(nombres.size() == manos.size(), "no hay nombres de mano repetidos")
	comprobar(mal_suma.is_empty(), "todas las manos suman 14 fichas %s" % str(mal_suma))
	comprobar(mal_seccion.is_empty(), "todas las manos tienen una sección válida %s" % str(mal_seccion))
	comprobar(mal_ejemplo.is_empty(), "todas las manos se pueden formar con fichas reales %s" % str(mal_ejemplo))
	for seccion in Tarjeta.SECCIONES:
		comprobar(manos.any(func(m): return m["seccion"] == seccion), "la sección «%s» tiene manos" % seccion)
	comprobar(Validador.variantes(mano("Pares del 2 al 8")).size() == 3, "una mano de un palo tiene 3 variantes")
	comprobar(Validador.variantes(mano("Escalera de tres")).size() == 21, "escalera: 3 palos x 7 valores de X")


func probar_manos_ganadoras() -> void:
	print("Manos ganadoras:")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8 car8"),
		mano("Pares del 2 al 8")), "pares del 2 al 8 en caracteres")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 bam8 bam8 bam8"),
		mano("Pares del 2 al 8")), "pares mezclando palos NO vale")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor cir5 cir5 cir5 cir5 cir6 cir6 cir6 cir6 cir7 cir7 cir7 cir7"),
		mano("Escalera de tres")), "escalera 5-6-7 en círculos")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor flor cir5 cir5 cir5 cir5 cir6 cir6 cir6 cir6 cir8 cir8 cir8 cir8"),
		mano("Escalera de tres")), "escalera con un hueco NO vale")
	comprobar(Validador.es_mano_ganadora(
		fichas("bam2 bam2 bam2 dB dB dB dB cir2 cir2 cir2 car6 car6 car6 car6"),
		mano("Año 2026")), "año 2026 con tres palos distintos")
	comprobar(not Validador.es_mano_ganadora(
		fichas("bam2 bam2 bam2 dB dB dB dB cir2 cir2 cir2 cir6 cir6 cir6 cir6"),
		mano("Año 2026")), "año 2026 repitiendo palo NO vale")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor flor dV dV dV dV dR dR dR dR dB dB dB"),
		mano("Tres dragones")), "tres dragones")
	comprobar(Validador.es_mano_ganadora(
		fichas("bam3 bam3 bam4 bam4 bam5 bam5 bam6 bam6 bam7 bam7 bam8 bam8 bam9 bam9"),
		mano("Parejas en escalera")), "parejas del 3 al 9")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8"),
		mano("Pares del 2 al 8")), "13 fichas nunca son mano ganadora")
	var ganadora := Validador.buscar_mano_ganadora(
		fichas("vN vN vN vN vE vE vE vO vO vO vS vS vS vS"), Tarjeta.manos())
	comprobar(ganadora.get("nombre", "") == "Los cuatro vientos", "buscar_mano_ganadora encuentra los vientos")


func probar_comodines() -> void:
	print("Comodines:")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 comodin car4 comodin comodin car6 car6 car6 car8 car8 car8"),
		mano("Pares del 2 al 8")), "los comodines completan pungs")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor comodin car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8 car8"),
		mano("Pares del 2 al 8")), "un comodín NO puede completar la pareja de flores")
	comprobar(not Validador.es_mano_ganadora(
		fichas("bam3 comodin bam4 bam4 bam5 bam5 bam6 bam6 bam7 bam7 bam8 bam8 bam9 bam9"),
		mano("Parejas en escalera")), "un comodín NO vale en una mano de parejas")
	comprobar(Validador.es_mano_ganadora(
		fichas("vN vN comodin comodin vE vE vE vO vO comodin vS vS vS vS"),
		mano("Los cuatro vientos")), "vientos con 3 comodines")


func probar_consejos() -> void:
	print("Consejos:")
	var casi := fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8 vN")
	var cercanas := Validador.manos_mas_cercanas(casi, Tarjeta.manos(), 3)
	comprobar(cercanas.size() == 3, "devuelve las 3 manos más cercanas")
	comprobar(cercanas[0]["mano"]["nombre"] == "Pares del 2 al 8", "la más cercana es 'Pares del 2 al 8'")
	comprobar(cercanas[0]["faltan"] == 1, "le falta 1 ficha")
	var utiles := Validador.ids_utiles(casi, cercanas[0])
	comprobar(utiles.size() == 13, "13 fichas útiles")
	comprobar(not utiles.has(casi[13].id), "el viento Norte es la ficha que sobra")


func probar_asesor() -> void:
	print("Asesor:")
	var m := fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 comodin vN dR bam7")
	var sobran := Asesor.fichas_que_sobran(m, Tarjeta.manos(), 3)
	comprobar(sobran.size() == 3, "elige 3 fichas")
	var claves := []
	for f in sobran:
		claves.append(f.clave())
	claves.sort()
	comprobar(claves == ["bam7", "dR", "vN"], "elige las 3 fichas que no encajan (%s)" % str(claves))
	var solo_comodines := fichas("comodin comodin comodin comodin vN")
	comprobar(Asesor.fichas_que_sobran(solo_comodines, Tarjeta.manos(), 3).size() == 1,
		"nunca elige comodines")


func _repartir_cuatro(semilla: int) -> Array:
	var mazo := Mazo.new(semilla)
	mazo.barajar()
	return [mazo.repartir(13), mazo.repartir(13), mazo.repartir(13), mazo.repartir(13)]


func _ids_de(manos: Array) -> Array:
	var ids := []
	for m in manos:
		for f in m:
			ids.append(f.id)
	ids.sort()
	return ids


func _comodines_por_mano(manos: Array) -> Array:
	var res := []
	for m in manos:
		res.append(Validador.contar(m)["comodines"])
	return res


func probar_charleston() -> void:
	print("Charleston:")
	var manos := _repartir_cuatro(777)
	var ids_antes := _ids_de(manos)
	var comodines_antes := _comodines_por_mano(manos)
	var ch := Charleston.new(manos, Tarjeta.manos())

	comprobar(ch.direccion_actual() == Charleston.DERECHA, "el primer pase es a la derecha")
	comprobar(ch.validar_pase(ch.mano_jugador().slice(0, 2)) != "", "pasar 2 fichas NO vale")
	var comodin := Ficha.new(Ficha.Tipo.COMODIN, "", 0, 999)
	ch.mano_jugador().append(comodin)
	var con_comodin: Array[Ficha] = [comodin, ch.mano_jugador()[0], ch.mano_jugador()[1]]
	comprobar(ch.validar_pase(con_comodin).contains("comodines"), "pasar un comodín NO vale")
	ch.mano_jugador().erase(comodin)

	# El jugador de la izquierda (asiento 3) pasa a su derecha, que eres tú.
	var esperado := Asesor.fichas_que_sobran(manos[3], Tarjeta.manos(), 3)
	var recibidas := ch.pasar(Asesor.fichas_que_sobran(ch.mano_jugador(), Tarjeta.manos(), 3))
	comprobar(recibidas == esperado, "en el pase a la derecha recibes del jugador de tu izquierda")
	comprobar(ch.direccion_actual() == Charleston.ENFRENTE, "el segundo pase es enfrente")
	ch.pasar(Asesor.fichas_que_sobran(ch.mano_jugador(), Tarjeta.manos(), 3))
	comprobar(ch.direccion_actual() == Charleston.IZQUIERDA, "el tercer pase es a la izquierda")
	ch.pasar(Asesor.fichas_que_sobran(ch.mano_jugador(), Tarjeta.manos(), 3))
	comprobar(ch.etapa == Charleston.Etapa.PREGUNTA_SEGUNDO, "después de 3 pases se pregunta por el segundo")

	ch.decidir_segundo(true)
	comprobar(ch.direccion_actual() == Charleston.IZQUIERDA, "el segundo Charleston empieza a la izquierda")
	for _i in 3:
		ch.pasar(Asesor.fichas_que_sobran(ch.mano_jugador(), Tarjeta.manos(), 3))
	comprobar(ch.etapa == Charleston.Etapa.CORTESIA, "después llega el pase de cortesía")
	var cuatro := ch.mano_jugador().slice(0, 4)
	comprobar(ch.validar_pase(cuatro) != "", "en la cortesía NO se pueden pasar 4")
	var dos := Asesor.fichas_que_sobran(ch.mano_jugador(), Tarjeta.manos(), 2)
	comprobar(ch.pasar(dos).size() == 2, "en la cortesía recibes tantas como pasas")
	comprobar(ch.terminado(), "el Charleston termina")

	var tamanos_ok := true
	for m in manos:
		tamanos_ok = tamanos_ok and m.size() == 13
	comprobar(tamanos_ok, "todos siguen con 13 fichas")
	comprobar(_ids_de(manos) == ids_antes, "no se pierde ni se duplica ninguna ficha")
	comprobar(_comodines_por_mano(manos) == comodines_antes, "nadie ha pasado comodines")

	var otro := Charleston.new(_repartir_cuatro(42), Tarjeta.manos())
	for _i in 3:
		otro.pasar(Asesor.fichas_que_sobran(otro.mano_jugador(), Tarjeta.manos(), 3))
	otro.decidir_segundo(false)
	comprobar(otro.etapa == Charleston.Etapa.CORTESIA, "si no quieres el segundo, se pasa a la cortesía")
	otro.saltar_cortesia()
	comprobar(otro.terminado(), "saltar la cortesía termina el Charleston")


func probar_partida() -> void:
	print("Partida:")
	var p := Partida.new(Tarjeta.manos(), 2, 2024)
	comprobar(p.manos[2].size() == 14, "el Este recibe 14 fichas")
	comprobar(p.manos[0].size() == 13 and p.manos[1].size() == 13 and p.manos[3].size() == 13, "los demás reciben 13")
	comprobar(p.mazo.quedan() == 152 - 53, "quedan 99 fichas en el muro")
	comprobar(p.turno == 2, "empieza el Este")
	comprobar(p.viento(2) == "Este" and p.viento(3) == "Sur" and p.viento(0) == "Oeste" and p.viento(1) == "Norte",
		"los vientos siguen hacia la derecha: Este, Sur, Oeste, Norte")
	comprobar(not p.debe_robar(), "el Este empieza descartando sin robar")

	# Partida entera con los 4 jugadores controlados por la máquina.
	var turnos := 0
	var orden_correcto := true
	while not p.terminada and turnos < 1000:
		var antes := p.turno
		p.jugar_turno_rival()
		if not p.terminada and p.turno != (antes + 1) % 4:
			orden_correcto = false
		turnos += 1
	comprobar(p.terminada, "la partida termina (%d turnos)" % turnos)
	comprobar(orden_correcto, "el turno siempre pasa al jugador de la derecha")
	var total := p.mazo.quedan() + p.descartes.size()
	for m in p.manos:
		total += m.size()
	comprobar(total == 152, "no se pierde ninguna ficha")
	if p.ganador >= 0:
		comprobar(Validador.es_mano_ganadora(p.manos[p.ganador], p.mano_ganadora), "la mano ganadora es válida")
	else:
		comprobar(p.mazo.quedan() == 0, "si nadie gana, es porque se acabó el muro")
	var comodines_descartados := 0
	for d in p.descartes:
		if d["ficha"].es_comodin():
			comodines_descartados += 1
	comprobar(comodines_descartados == 0, "la máquina no descarta comodines")


func probar_lecciones() -> void:
	print("Lecciones:")
	comprobar(Lecciones.ORDEN.size() == Lecciones.TODAS.size(), "todas las lecciones están en el índice de Reglas")
	var completas := true
	for clave in Lecciones.ORDEN:
		var l: Dictionary = Lecciones.TODAS.get(clave, {})
		for campo in ["titulo", "texto", "mesa"]:
			if l.get(campo, "") == "":
				completas = false
	comprobar(completas, "cada lección tiene título, texto y consejo para la mesa real")
	# Cada lección que usa la pantalla principal debe existir.
	var codigo := FileAccess.get_file_as_string("res://scripts/ui/main.gd")
	var regex := RegEx.new()
	regex.compile("\"([a-z_]+)\"")
	var faltan := []
	for clave in Lecciones.ORDEN:
		if not codigo.contains("\"%s\"" % clave):
			faltan.append(clave)
	comprobar(faltan.is_empty(), "la pantalla usa todas las lecciones (sin usar: %s)" % str(faltan))
	var desconocidas := []
	for m in regex.search_all(codigo):
		var clave := m.get_string(1)
		if codigo.contains("mostrar_leccion(\"%s\")" % clave) and not Lecciones.TODAS.has(clave):
			desconocidas.append(clave)
	comprobar(desconocidas.is_empty(), "no se muestra ninguna lección inexistente %s" % str(desconocidas))


## Crea un grupo expuesto a partir de un texto. Ejemplo: grupo("car4 car4 comodin").
func grupo(texto: String) -> Dictionary:
	var f := fichas(texto)
	var clave := ""
	for x in f:
		if not x.es_comodin():
			clave = x.clave()
	return {"clave": clave, "fichas": f}


func probar_expuestas() -> void:
	print("Grupos expuestos:")
	var pares := mano("Pares del 2 al 8")
	var ocultas := fichas("flor flor car2 car2 car2 car6 car6 car6 car8 car8 car8")
	comprobar(Validador.es_mano_ganadora(ocultas, pares, [grupo("car4 car4 comodin")]),
		"gana con un pung expuesto que encaja en la mano")
	comprobar(not Validador.es_mano_ganadora(ocultas, pares, [grupo("bam4 bam4 bam4")]),
		"NO gana si el grupo expuesto es de otro palo")
	var ocultas10 := fichas("flor flor car2 car2 car2 car6 car6 car6 car8 car8")
	comprobar(not Validador.es_mano_ganadora(ocultas10, pares, [grupo("car4 car4 car4 car4")]),
		"NO gana si expone un kong donde la mano pide un pung")
	var parejas := fichas("bam3 bam3 bam4 bam4 bam5 bam5 bam6 bam6 bam7 bam7 bam8")
	comprobar(Validador.analizar(parejas, mano("Parejas en escalera"), [grupo("vN vN vN")])["faltan"] == Validador.IMPOSIBLE,
		"una mano oculta es imposible si tienes grupos expuestos")


## Prepara una partida con manos conocidas: tú (asiento 0) acabas de descartar `descarte`.
func partida_preparada(mano1: String, mano2: String, mano3: String, descarte: String) -> Partida:
	var p := Partida.new(Tarjeta.manos(), 0, 5)
	p.manos[0] = fichas(descarte + " vN vN vN vE vE vE vO vO vO vS vS vS")
	p.manos[1] = fichas(mano1)
	p.manos[2] = fichas(mano2)
	p.manos[3] = fichas(mano3)
	p.turno = 0
	p.descartar(p.manos[0][0])
	return p


func probar_cantos() -> void:
	print("Cantar descartes:")
	var casi := "flor flor car2 car2 car2 car4 car4 car6 car6 car6 car8 car8 car8"
	var cerca := "flor flor car2 car2 car2 car4 car4 car6 car6 vN car8 car8 car8"
	var nada := "bam1 bam3 bam5 bam7 bam9 cir1 cir3 cir5 cir7 cir9 dR dV vE"

	var p := partida_preparada(nada, cerca, casi, "car4")
	var ficha: Ficha = p.descartes.back()["ficha"]
	var ev := p.evaluar_canto(3, ficha)
	comprobar(ev["mahjong"], "con el car4 descartado, Izquierda hace Mahjong")
	ev = p.evaluar_canto(2, ficha)
	comprobar(not ev["mahjong"] and ev["cant"] == 3, "a Enfrente le conviene cantar un pung de car4")
	comprobar(ev["faltan_despues"] == ev["faltan_antes"] - 1, "cantar le acerca una ficha a su mano")
	comprobar(p.evaluar_canto(1, ficha)["cant"] == 0, "a Derecha no le sirve")

	var cantos := p.cantos_de_rivales()
	comprobar(cantos.size() == 2, "dos rivales quieren la ficha")
	comprobar(p.elegir_canto(cantos)["jugador"] == 3, "el Mahjong tiene preferencia aunque esté más lejos")

	var p2 := partida_preparada(cerca, cerca, nada, "car4")
	comprobar(p2.elegir_canto(p2.cantos_de_rivales())["jugador"] == 1,
		"si dos quieren exponer, gana el más cercano en turno")
	var descartes_antes := p2.descartes.size()
	p2.cantar(1, 3, false)
	comprobar(p2.descartes.size() == descartes_antes - 1, "la ficha cantada sale de los descartes")
	comprobar(p2.expuestas[1].size() == 1 and p2.expuestas[1][0]["fichas"].size() == 3, "se expone un pung")
	comprobar(p2.turno == 1 and not p2.debe_robar(), "quien canta descarta sin robar")
	comprobar(p2.total_fichas(1) == 14, "quien canta tiene 14 fichas en total")

	var p3 := partida_preparada(casi, nada, nada, "comodin")
	comprobar(p3.cantos_de_rivales().is_empty(), "un comodín descartado no se puede cantar")

	var impares := "cir1 cir3 cir3 cir3 cir5 cir5 cir5 cir5 cir7 cir7 cir7 cir9 cir9"
	var p4 := partida_preparada(impares, nada, nada, "cir1")
	comprobar(p4.evaluar_canto(1, p4.descartes.back()["ficha"])["mahjong"],
		"se puede cantar para una pareja si es para hacer Mahjong")
	var impares_lejos := "cir1 cir3 cir3 cir3 cir5 cir5 cir5 cir5 cir7 cir7 cir7 cir9 vN"
	var p5 := partida_preparada(impares_lejos, nada, nada, "cir1")
	comprobar(p5.evaluar_canto(1, p5.descartes.back()["ficha"])["cant"] == 0,
		"NO se canta para completar una pareja si no es Mahjong")


func probar_cambio_de_comodin() -> void:
	print("Cambiar comodín:")
	var p := Partida.new(Tarjeta.manos(), 0, 5)
	p.expuestas[2] = [grupo("bam5 bam5 comodin")]
	p.manos[0] = fichas("vN vN vN vE vE vE vO vO vO vS vS vS")
	var bam5 := fichas("bam5")[0]
	p.manos[0].append(bam5)
	var opciones := p.cambios_de_comodin(0)
	comprobar(opciones.size() == 1 and opciones[0]["ficha"] == bam5, "puedes cambiar tu bam5 por el comodín")
	var comodin := p.cambiar_comodin(0, opciones[0])
	comprobar(comodin.es_comodin() and p.manos[0].has(comodin), "el comodín pasa a tu mano")
	comprobar(not p.manos[0].has(bam5) and p.expuestas[2][0]["fichas"].has(bam5), "tu bam5 queda en el grupo expuesto")
	comprobar(p.cambios_de_comodin(0).is_empty(), "ya no quedan comodines que cambiar")

	print("Partidas simuladas con cantos:")
	var ganadas := 0
	var todo_bien := true
	for semilla in range(1, 11):
		var sim := Partida.new(Tarjeta.manos(), semilla % 4, semilla)
		sim.simular_hasta_el_final()
		var total := sim.mazo.quedan() + sim.descartes.size()
		for j in 4:
			total += sim.total_fichas(j)
		todo_bien = todo_bien and total == 152 and sim.terminada
		if sim.ganador >= 0:
			ganadas += 1
			todo_bien = todo_bien and Validador.es_mano_ganadora(
				sim.manos[sim.ganador], sim.mano_ganadora, sim.expuestas[sim.ganador])
	comprobar(todo_bien, "10 partidas: terminan, no se pierden fichas y los ganadores son válidos")
	comprobar(ganadas > 0, "con cantos alguien gana alguna vez (%d de 10)" % ganadas)
