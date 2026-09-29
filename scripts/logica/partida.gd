class_name Partida
extends RefCounted
## Una partida completa entre 4 jugadores: tú (asiento 0) y 3 rivales de la máquina.
##
## Asientos: 0 = tú, 1 = el de tu derecha, 2 = el de enfrente, 3 = el de tu izquierda.
## El turno avanza hacia la DERECHA: 0 -> 1 -> 2 -> 3 -> 0...
##
## Uno de los jugadores es el ESTE (la "banca"): recibe 14 fichas en lugar de 13
## y empieza descartando sin robar. Los demás vientos siguen hacia la derecha:
## Este -> Sur -> Oeste -> Norte.
##
## CANTAR: cuando alguien descarta, otro jugador puede quedarse esa ficha:
##   - para formar un grupo de 3, 4 o 5 (pung, kong, quint) que deja EXPUESTO
##     (boca arriba en la mesa), y después descarta; o
##   - para hacer ¡Mahjong! (solo en este caso vale para una pareja o suelta).
##   Si varios la quieren, gana el Mahjong; si empatan, el más cercano en turno.

const NOMBRES := ["Tú", "Derecha", "Enfrente", "Izquierda"]
const VIENTOS := ["Este", "Sur", "Oeste", "Norte"]
const NOMBRE_GRUPO := {3: "pung", 4: "kong", 5: "quint"}

var mazo: Mazo
var manos_tarjeta: Array[Dictionary]
## Las fichas ocultas de cada jugador (cada una es un Array[Ficha]).
var manos: Array = []
## Los grupos expuestos de cada jugador: {"clave": String, "fichas": Array[Ficha]}.
var expuestas: Array = [[], [], [], []]
## Las fichas descartadas que siguen en la mesa, en orden: {"ficha": Ficha, "jugador": int}
var descartes: Array[Dictionary] = []
## Asiento del jugador que es Este.
var este := 0
## Asiento del jugador al que le toca.
var turno := 0
var terminada := false
## Asiento del ganador, o -1 si no hay (todavía o por empate).
var ganador := -1
var mano_ganadora: Dictionary = {}


func _init(p_manos_tarjeta: Array[Dictionary], p_este: int = 0, semilla: int = 0) -> void:
	manos_tarjeta = p_manos_tarjeta
	este = p_este
	mazo = Mazo.new(semilla)
	mazo.barajar()
	for i in 4:
		manos.append(mazo.repartir(13))
	# Este recibe una ficha más.
	manos[este].append(mazo.robar())
	turno = este


## Nombre del jugador con su viento. Ejemplo: "Derecha (Sur)".
func nombre(jugador: int) -> String:
	return "%s (%s)" % [NOMBRES[jugador], viento(jugador)]


func viento(jugador: int) -> String:
	return VIENTOS[(jugador - este + 4) % 4]


func crear_charleston() -> Charleston:
	return Charleston.new(manos, manos_tarjeta)


## Fichas ocultas + expuestas de un jugador.
func total_fichas(jugador: int) -> int:
	var total: int = manos[jugador].size()
	for e in expuestas[jugador]:
		total += e["fichas"].size()
	return total


## ¿Tiene que robar el jugador del turno? (Si tiene 14 fichas, le toca descartar).
func debe_robar() -> bool:
	return total_fichas(turno) == 13


## Lo que le falta a un jugador para su mano más cercana.
func mejor_analisis(jugador: int) -> Dictionary:
	return Validador.manos_mas_cercanas(manos[jugador], manos_tarjeta, 1, expuestas[jugador])[0]


## El jugador del turno roba una ficha. Devuelve null si el muro está vacío
## (entonces la partida termina en empate).
func robar() -> Ficha:
	var ficha := mazo.robar()
	if ficha == null:
		terminada = true
		return null
	manos[turno].append(ficha)
	comprobar_mahjong()
	return ficha


## Si el jugador del turno tiene una mano de la tarjeta, gana la partida.
func comprobar_mahjong() -> bool:
	var ganadora := Validador.buscar_mano_ganadora(manos[turno], manos_tarjeta, expuestas[turno])
	if ganadora.is_empty():
		return false
	ganador = turno
	mano_ganadora = ganadora
	terminada = true
	return true


## El jugador del turno descarta una ficha y el turno pasa a su derecha.
func descartar(ficha: Ficha) -> void:
	assert(manos[turno].has(ficha), "Esa ficha no está en la mano del jugador del turno")
	manos[turno].erase(ficha)
	descartes.append({"ficha": ficha, "jugador": turno})
	turno = (turno + 1) % 4


# =============================================================================
#  CANTAR DESCARTES
# =============================================================================

## ¿Le sirve a `jugador` el último descarte? Devuelve:
##   "mahjong": true si con esa ficha gana.
##   "cant": tamaño del grupo que le conviene exponer (3, 4 o 5), o 0 si no le conviene.
##   "faltan_antes" / "faltan_despues": fichas que le faltan sin cantar y cantando.
##   "mano": nombre de la mano de la tarjeta a la que se acerca.
func evaluar_canto(jugador: int, ficha: Ficha) -> Dictionary:
	var resultado := {"mahjong": false, "cant": 0, "faltan_antes": 0, "faltan_despues": 0, "mano": ""}
	# Un comodín descartado está "muerto": nadie puede cantarlo.
	if ficha.es_comodin():
		return resultado
	var mano: Array[Ficha] = manos[jugador]
	var con_ficha: Array[Ficha] = mano.duplicate()
	con_ficha.append(ficha)
	if not Validador.buscar_mano_ganadora(con_ficha, manos_tarjeta, expuestas[jugador]).is_empty():
		resultado["mahjong"] = true
		return resultado

	var antes := mejor_analisis(jugador)
	resultado["faltan_antes"] = antes["faltan"]
	var disponibles := 0
	for f in mano:
		if f.es_comodin() or f.clave() == ficha.clave():
			disponibles += 1
	for cant in [3, 4, 5]:
		if disponibles < cant - 1:
			break
		var usadas := _fichas_para_grupo(mano, ficha.clave(), cant - 1)
		var resto: Array[Ficha] = mano.duplicate()
		for f in usadas:
			resto.erase(f)
		var nuevas_expuestas: Array = expuestas[jugador].duplicate()
		nuevas_expuestas.append({"clave": ficha.clave(), "fichas": usadas + [ficha]})
		var despues: Dictionary = Validador.manos_mas_cercanas(resto, manos_tarjeta, 1, nuevas_expuestas)[0]
		# Solo conviene si la ficha nos acerca a una mano (igual que robarla del muro).
		if despues["faltan"] < antes["faltan"] and (resultado["cant"] == 0 or despues["faltan"] < resultado["faltan_despues"]):
			resultado["cant"] = cant
			resultado["faltan_despues"] = despues["faltan"]
			resultado["mano"] = despues["mano"]["nombre"]
	return resultado


## Qué rivales quieren el último descarte. Cada canto: {"jugador", "mahjong", "cant"}.
## Con `incluir_asiento_0` también decide la máquina por ti (para simular partidas).
func cantos_de_rivales(incluir_asiento_0: bool = false) -> Array[Dictionary]:
	var cantos: Array[Dictionary] = []
	if descartes.is_empty():
		return cantos
	var ultimo: Dictionary = descartes.back()
	for j in range(0 if incluir_asiento_0 else 1, 4):
		if j == ultimo["jugador"]:
			continue
		var ev := evaluar_canto(j, ultimo["ficha"])
		if ev["mahjong"] or ev["cant"] > 0:
			cantos.append({"jugador": j, "mahjong": ev["mahjong"], "cant": ev["cant"]})
	return cantos


## Entre varios cantos, ¿quién se queda la ficha?
## 1) El que hace Mahjong. 2) Si empatan, el más cercano en turno a quien descartó.
func elegir_canto(cantos: Array[Dictionary]) -> Dictionary:
	if cantos.is_empty():
		return {}
	var quien_descarto: int = descartes.back()["jugador"]
	var ordenados := cantos.duplicate()
	ordenados.sort_custom(func(a, b):
		if a["mahjong"] != b["mahjong"]:
			return a["mahjong"]
		return (a["jugador"] - quien_descarto + 4) % 4 < (b["jugador"] - quien_descarto + 4) % 4)
	return ordenados[0]


## `jugador` se queda el último descarte. Si no es Mahjong, expone un grupo de `cant`
## fichas y le toca descartar. Devuelve la ficha cantada.
func cantar(jugador: int, cant: int, es_mahjong: bool) -> Ficha:
	var ficha: Ficha = descartes.pop_back()["ficha"]
	turno = jugador
	if es_mahjong:
		manos[jugador].append(ficha)
		comprobar_mahjong()
		return ficha
	var usadas := _fichas_para_grupo(manos[jugador], ficha.clave(), cant - 1)
	for f in usadas:
		manos[jugador].erase(f)
	var grupo: Array[Ficha] = usadas.duplicate()
	grupo.append(ficha)
	expuestas[jugador].append({"clave": ficha.clave(), "fichas": grupo})
	return ficha


## Elige las fichas de la mano para completar un grupo: primero las naturales
## (así se guardan los comodines, que valen más) y después comodines.
func _fichas_para_grupo(mano: Array[Ficha], clave: String, cantidad: int) -> Array[Ficha]:
	var elegidas: Array[Ficha] = []
	for f in mano:
		if elegidas.size() < cantidad and not f.es_comodin() and f.clave() == clave:
			elegidas.append(f)
	for f in mano:
		if elegidas.size() < cantidad and f.es_comodin():
			elegidas.append(f)
	return elegidas


# =============================================================================
#  CAMBIAR UN COMODÍN EXPUESTO
# =============================================================================

## En tu turno, si un grupo expuesto (tuyo o de otro) tiene un comodín y tú tienes
## la ficha real, puedes cambiarla por el comodín.
## Devuelve las opciones: {"dueno": int, "indice": int, "ficha": Ficha}.
func cambios_de_comodin(jugador: int) -> Array[Dictionary]:
	var opciones: Array[Dictionary] = []
	for dueno in 4:
		for i in expuestas[dueno].size():
			var grupo: Dictionary = expuestas[dueno][i]
			if not grupo["fichas"].any(func(f): return f.es_comodin()):
				continue
			for f in manos[jugador]:
				if not f.es_comodin() and f.clave() == grupo["clave"]:
					opciones.append({"dueno": dueno, "indice": i, "ficha": f})
					break
	return opciones


## Hace un cambio de comodín. Devuelve el comodín que se lleva el jugador.
func cambiar_comodin(jugador: int, opcion: Dictionary) -> Ficha:
	var grupo: Array = expuestas[opcion["dueno"]][opcion["indice"]]["fichas"]
	var comodin: Ficha = null
	for f in grupo:
		if f.es_comodin():
			comodin = f
			break
	grupo[grupo.find(comodin)] = opcion["ficha"]
	manos[jugador].erase(opcion["ficha"])
	manos[jugador].append(comodin)
	return comodin


func _deshacer_cambio(jugador: int, opcion: Dictionary, comodin: Ficha) -> void:
	var grupo: Array = expuestas[opcion["dueno"]][opcion["indice"]]["fichas"]
	grupo[grupo.find(opcion["ficha"])] = comodin
	manos[jugador].erase(comodin)
	manos[jugador].append(opcion["ficha"])


# =============================================================================
#  RIVALES DE LA MÁQUINA
# =============================================================================

## Juega el turno completo de un rival de la máquina.
## Devuelve qué pasó: {"jugador", "robada" (o null), "descartada" (o null), "cambios": int}.
func jugar_turno_rival() -> Dictionary:
	var jugador := turno
	var resultado := {"jugador": jugador, "robada": null, "descartada": null, "cambios": 0}
	if debe_robar():
		resultado["robada"] = robar()
	else:
		comprobar_mahjong()  # Este puede empezar ya con una mano ganadora
	if terminada:
		return resultado

	# Cambia comodines expuestos, pero solo si no empeora su mano.
	for _intento in 4:
		var hecho := false
		for opcion in cambios_de_comodin(jugador):
			var antes: int = mejor_analisis(jugador)["faltan"]
			var comodin := cambiar_comodin(jugador, opcion)
			if mejor_analisis(jugador)["faltan"] <= antes:
				hecho = true
				resultado["cambios"] += 1
				break
			_deshacer_cambio(jugador, opcion, comodin)
		if not hecho:
			break
	if comprobar_mahjong():
		return resultado

	var descarte: Ficha = Asesor.fichas_que_sobran(manos[jugador], manos_tarjeta, 1, expuestas[jugador])[0]
	descartar(descarte)
	resultado["descartada"] = descarte
	return resultado


## Simula una partida entera con los 4 jugadores controlados por la máquina
## (se usa en las pruebas). Devuelve cuántos turnos duró.
func simular_hasta_el_final() -> int:
	var turnos := 0
	while not terminada and turnos < 1000:
		var r := jugar_turno_rival()
		turnos += 1
		if r["descartada"] == null:
			continue
		var canto := elegir_canto(cantos_de_rivales(true))
		if not canto.is_empty():
			cantar(canto["jugador"], canto["cant"], canto["mahjong"])
	return turnos
