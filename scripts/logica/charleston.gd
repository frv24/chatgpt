class_name Charleston
extends RefCounted
## El Charleston: el intercambio de fichas antes de empezar a jugar.
## Es lo más característico del Mahjong americano.
##
## Reglas (las oficiales, simplificadas):
##   1. PRIMER CHARLESTON (obligatorio): 3 pases de 3 fichas cada uno.
##        derecha -> enfrente -> izquierda
##   2. SEGUNDO CHARLESTON (opcional, solo si todos quieren): otros 3 pases,
##      en orden inverso.
##        izquierda -> enfrente -> derecha
##   3. PASE DE CORTESÍA (opcional): de 0 a 3 fichas con el jugador de enfrente.
##   - Los comodines NUNCA se pueden pasar.
##   - PASE A CIEGAS: en el último pase de cada Charleston (el primer "izquierda" y el
##     segundo "derecha") puedes pasar, sin mirarlas, fichas que te acaban de dar.
##     Por eso las fichas que recibes en el pase anterior ("enfrente") llegan boca abajo
##     a una bandeja: puedes pasarlas a ciegas o recogerlas y mirarlas.
##
## Asientos: 0 = tú, 1 = el jugador de tu derecha, 2 = el de enfrente,
## 3 = el de tu izquierda. Para pasar "a la derecha", el jugador i le da
## sus fichas al jugador (i + 1) % 4; "enfrente" es + 2 e "izquierda" es + 3.

enum Etapa { PRIMERO, PREGUNTA_SEGUNDO, SEGUNDO, CORTESIA, TERMINADO }

const DERECHA := 1
const ENFRENTE := 2
const IZQUIERDA := 3
const NOMBRE_DIRECCION := {DERECHA: "la DERECHA", ENFRENTE: "ENFRENTE", IZQUIERDA: "la IZQUIERDA"}
const FLECHA := {DERECHA: "→", ENFRENTE: "↑", IZQUIERDA: "←"}

const ORDEN_PRIMERO := [DERECHA, ENFRENTE, IZQUIERDA]
const ORDEN_SEGUNDO := [IZQUIERDA, ENFRENTE, DERECHA]
const FICHAS_POR_PASE := 3

## Las manos de los 4 jugadores (índice 0 = tú).
var manos: Array = []
var manos_tarjeta: Array[Dictionary]
var etapa := Etapa.PRIMERO
## Qué pase toca dentro del Charleston actual (0, 1 o 2).
var indice_pase := 0
## Fichas que acabas de recibir (para resaltarlas en pantalla).
var ultimas_recibidas: Array[Ficha] = []
## Fichas recibidas boca abajo, disponibles para el pase a ciegas.
var bandeja: Array[Ficha] = []
## Fichas boca abajo que no pasaste en el último pase y volvieron a tu mano.
var reveladas: Array[Ficha] = []


func _init(p_manos: Array, p_manos_tarjeta: Array[Dictionary]) -> void:
	manos = p_manos
	manos_tarjeta = p_manos_tarjeta


func mano_jugador() -> Array[Ficha]:
	return manos[0]


func terminado() -> bool:
	return etapa == Etapa.TERMINADO


## ¿El pase actual permite pasar a ciegas? (El último de cada Charleston.)
func es_pase_ciego() -> bool:
	return (etapa == Etapa.PRIMERO or etapa == Etapa.SEGUNDO) and indice_pase == 2


## Recoger las fichas de la bandeja (mirarlas y ponerlas en la mano).
## Devuelve las fichas recogidas.
func recoger_bandeja() -> Array[Ficha]:
	var recogidas := bandeja.duplicate()
	mano_jugador().append_array(bandeja)
	bandeja.clear()
	return recogidas


## Dirección del pase que toca ahora.
func direccion_actual() -> int:
	match etapa:
		Etapa.PRIMERO:
			return ORDEN_PRIMERO[indice_pase]
		Etapa.SEGUNDO:
			return ORDEN_SEGUNDO[indice_pase]
		Etapa.CORTESIA:
			return ENFRENTE
	return 0


## Texto corto que explica en qué punto del Charleston estamos.
func descripcion() -> String:
	match etapa:
		Etapa.PRIMERO:
			return "Primer Charleston · pase %d de 3: elige 3 fichas para pasar a %s %s%s" % [
				indice_pase + 1, NOMBRE_DIRECCION[direccion_actual()], FLECHA[direccion_actual()], _nota_ciego()]
		Etapa.PREGUNTA_SEGUNDO:
			return "Primer Charleston terminado. ¿Quieres hacer el segundo Charleston?"
		Etapa.SEGUNDO:
			return "Segundo Charleston · pase %d de 3: elige 3 fichas para pasar a %s %s%s" % [
				indice_pase + 1, NOMBRE_DIRECCION[direccion_actual()], FLECHA[direccion_actual()], _nota_ciego()]
		Etapa.CORTESIA:
			return "Pase de cortesía: elige de 0 a 3 fichas para pasar ENFRENTE ↑ (0 = no pasar nada)"
	return "Charleston terminado. ¡A jugar!"


func _nota_ciego() -> String:
	if es_pase_ciego() and not bandeja.is_empty():
		return " (puedes incluir fichas boca abajo: pase a ciegas)"
	return ""


## Comprueba si un pase es válido. Devuelve "" si está bien, o el motivo del error.
func validar_pase(pase: Array[Ficha]) -> String:
	if etapa == Etapa.CORTESIA:
		if pase.size() > FICHAS_POR_PASE:
			return "En el pase de cortesía puedes pasar como máximo 3 fichas."
	elif etapa == Etapa.PRIMERO or etapa == Etapa.SEGUNDO:
		if pase.size() != FICHAS_POR_PASE:
			return "Debes elegir exactamente 3 fichas (llevas %d)." % pase.size()
	else:
		return "Ahora no toca pasar fichas."
	for f in pase:
		if f.es_comodin():
			return "Los comodines no se pueden pasar en el Charleston."
		if bandeja.has(f) and not es_pase_ciego():
			return "Ahora no se puede pasar a ciegas."
		if not mano_jugador().has(f) and not bandeja.has(f):
			return "Esa ficha no está en tu mano."
	return ""


## Hace un pase: tú das `pase_jugador` y los rivales eligen sus fichas.
## `pases_forzados` (asiento -> fichas) fija lo que pasa algún rival (lo usa el tutorial).
## Devuelve las fichas que recibes tú.
func pasar(pase_jugador: Array[Ficha], pases_forzados: Dictionary = {}) -> Array[Ficha]:
	assert(validar_pase(pase_jugador) == "", validar_pase(pase_jugador))
	var direccion := direccion_actual()

	# 1. Cada jugador elige qué pasa (a la vez, antes de recibir nada).
	var pases: Array = [pase_jugador, [], [], []]
	for i in range(1, 4):
		var cantidad := FICHAS_POR_PASE
		if etapa == Etapa.CORTESIA:
			# En la cortesía solo participa el de enfrente, y pasa las mismas que tú.
			cantidad = pase_jugador.size() if i == ENFRENTE else 0
		pases[i] = pases_forzados[i] if pases_forzados.has(i) else \
			Asesor.fichas_que_sobran(manos[i], manos_tarjeta, cantidad)

	# 2. Cada jugador quita de su mano (o de su bandeja) lo que pasa...
	for i in 4:
		for f in pases[i]:
			manos[i].erase(f)
			if i == 0:
				bandeja.erase(f)
	# 3. ...lo que quedó en tu bandeja sin pasar vuelve a tu mano...
	reveladas = recoger_bandeja()
	# 4. ...y cada uno recibe lo que le pasan.
	var siguiente_es_ciego := (etapa == Etapa.PRIMERO or etapa == Etapa.SEGUNDO) and indice_pase == 1
	for i in 4:
		var destino := (i + direccion) % 4
		for f in pases[i]:
			if destino == 0 and siguiente_es_ciego:
				bandeja.append(f)  # llegan boca abajo para el pase a ciegas
			else:
				manos[destino].append(f)

	ultimas_recibidas.assign(pases[(4 - direccion) % 4])
	# Las fichas de la bandeja que no pasaste también son "nuevas" para ti.
	ultimas_recibidas.append_array(reveladas)
	_avanzar()
	return ultimas_recibidas


## Después del primer Charleston: ¿se hace el segundo?
## Los rivales de la máquina siempre aceptan, así que decide el jugador.
func decidir_segundo(quiere: bool) -> void:
	if etapa != Etapa.PREGUNTA_SEGUNDO:
		return
	etapa = Etapa.SEGUNDO if quiere else Etapa.CORTESIA
	indice_pase = 0


## Saltar el pase de cortesía es lo mismo que pasar 0 fichas.
func saltar_cortesia() -> void:
	if etapa == Etapa.CORTESIA:
		pasar([])


func _avanzar() -> void:
	match etapa:
		Etapa.PRIMERO:
			indice_pase += 1
			if indice_pase == 3:
				etapa = Etapa.PREGUNTA_SEGUNDO
		Etapa.SEGUNDO:
			indice_pase += 1
			if indice_pase == 3:
				etapa = Etapa.CORTESIA
		Etapa.CORTESIA:
			etapa = Etapa.TERMINADO
