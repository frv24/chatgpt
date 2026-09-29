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

const NOMBRES := ["Tú", "Derecha", "Enfrente", "Izquierda"]
const VIENTOS := ["Este", "Sur", "Oeste", "Norte"]

var mazo: Mazo
var manos_tarjeta: Array[Dictionary]
## Las 4 manos (cada una es un Array[Ficha]).
var manos: Array = []
## Todas las fichas descartadas, en orden: {"ficha": Ficha, "jugador": int}
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


## ¿Tiene que robar el jugador del turno? (Si tiene 14 fichas, le toca descartar).
func debe_robar() -> bool:
	return manos[turno].size() == 13


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
	var ganadora := Validador.buscar_mano_ganadora(manos[turno], manos_tarjeta)
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


## Juega el turno completo de un rival de la máquina.
## Devuelve qué pasó: {"jugador", "robada" (o null), "descartada" (o null)}.
func jugar_turno_rival() -> Dictionary:
	var jugador := turno
	var resultado := {"jugador": jugador, "robada": null, "descartada": null}
	if debe_robar():
		resultado["robada"] = robar()
	elif manos[jugador].size() == 14:
		comprobar_mahjong()  # Este puede empezar ya con una mano ganadora
	if terminada:
		return resultado
	var descarte: Ficha = Asesor.fichas_que_sobran(manos[jugador], manos_tarjeta, 1)[0]
	descartar(descarte)
	resultado["descartada"] = descarte
	return resultado
