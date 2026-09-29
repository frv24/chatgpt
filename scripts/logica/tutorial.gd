class_name Tutorial
extends RefCounted
## La partida guiada para aprender a jugar.
##
## Es una partida PREPARADA: las fichas están colocadas para que en pocos pasos
## aprendas lo básico (tu mano, la tarjeta, el Charleston, cantar, descartar, robar)
## y termines ganando con «Pares del 2 al 8».
##
## Cada paso tiene:
##   "texto":    lo que dice el globo de ayuda.
##   "espera":   qué tiene que hacer el jugador para seguir:
##                 "continuar" -> pulsar «Continuar» en el globo;
##                 "fichas"    -> tocar las fichas de "claves";
##                 "pasar", "cantar", "descartar", "robar" -> pulsar ese botón;
##                 "rivales"   -> esperar a que jueguen los demás.
##   "resaltar": qué brilla en pantalla ("mano", "tarjeta", "nuevas", "fichas" o "boton").
##   "claves":   fichas que hay que tocar (en los pasos "fichas").

const OBJETIVO := "Pares del 2 al 8"
## El jugador de tu izquierda (asiento 3) es el Este: empieza él.
const ESTE := 3

const PASOS := [
	{"espera": "continuar", "resaltar": "",
		"texto": "¡Hola! Vamos a jugar una partida de práctica. Solo tienes que hacer lo que diga este mensaje. ¡Aquí no te puedes equivocar!"},
	{"espera": "continuar", "resaltar": "mano",
		"texto": "Estas son tus fichas: tienes 13. Cada palo tiene su color: Nopal es verde, Picado es rosa y Sol es naranja."},
	{"espera": "continuar", "resaltar": "tarjeta",
		"texto": "Para ganar, tus fichas tienen que formar una mano de la tarjeta. Hoy vamos a por «Pares del 2 al 8»: 2 flores, y tres 2, tres 4, tres 6 y tres 8, todos de Nopal."},
	{"espera": "continuar", "resaltar": "mano",
		"texto": "Las fichas con borde verde te sirven para esa mano. Las que se ven apagadas no te sirven."},
	{"espera": "fichas", "resaltar": "fichas", "claves": ["vS", "cir3", "dV"],
		"texto": "Antes de jugar, todos cambian 3 fichas: se llama «Charleston». Toca las 3 fichas que brillan: son las que no te sirven."},
	{"espera": "pasar", "resaltar": "boton",
		"texto": "¡Muy bien! Ahora pulsa «Pasar» para dárselas al jugador de tu derecha."},
	{"espera": "continuar", "resaltar": "nuevas",
		"texto": "A cambio, el jugador de tu izquierda te pasó 3 fichas (en amarillo). ¡Dos son 8 de Nopal, justo lo que buscabas! En una partida de verdad hay más pases; hoy practicamos solo uno."},
	{"espera": "continuar", "resaltar": "",
		"texto": "¡Empieza el juego! Cada jugador, por turnos, roba una ficha y tira otra. Hoy empieza el jugador de tu izquierda. Pulsa «Continuar» y mira qué ficha tira."},
	{"espera": "rivales", "resaltar": "",
		"texto": "El jugador de tu izquierda está pensando qué ficha tirar…"},
	{"espera": "cantar", "resaltar": "boton",
		"texto": "¡Tiró un 4 de Nopal! Tú tienes dos 4: si te la quedas, formas tres iguales (un «pung»). Quedarse la ficha que otro tira se llama «cantar». Pulsa «Cantar pung»."},
	{"espera": "fichas", "resaltar": "fichas", "claves": ["car1"],
		"texto": "Tus tres 4 quedan boca arriba sobre la mesa. Ahora te toca tirar una ficha: toca el 1 de Picado, que no te sirve."},
	{"espera": "descartar", "resaltar": "boton",
		"texto": "Pulsa «Descartar» para tirarla."},
	{"espera": "rivales", "resaltar": "",
		"texto": "Ahora juegan los demás, uno detrás de otro hacia la derecha: cada uno roba una ficha y tira otra…"},
	{"espera": "robar", "resaltar": "boton",
		"texto": "¡Te toca! Solo te falta un 8 de Nopal. Pulsa «Robar» para coger una ficha del muro."},
	{"espera": "continuar", "resaltar": "mano",
		"texto": "¡MAHJONG! Robaste el 8 que te faltaba y completaste «Pares del 2 al 8». ¡Así se gana! Ya sabes lo básico. Pulsa «Continuar» para elegir un nivel y jugar de verdad: te recomendamos empezar por Fácil."},
]

# Tus fichas al empezar, las que te pasa el jugador de tu izquierda en el Charleston
# y las que se roban del muro (en orden: Derecha, Enfrente, Izquierda y tú).
const TU_MANO := ["flor", "flor", "bam2", "bam2", "bam2", "bam4", "bam4",
	"bam6", "bam6", "bam6", "vS", "cir3", "dV"]
const TE_PASAN := ["bam8", "bam8", "car1"]
const PRIMER_DESCARTE := "bam4"
const ROBOS := ["vN", "dR", "cir9", "bam8"]


## Crea la partida preparada del tutorial.
static func crear_partida(manos_tarjeta: Array[Dictionary]) -> Partida:
	var p := Partida.new(manos_tarjeta, ESTE, 2026, "tutorial")
	# Todas las fichas vuelven a un montón y se colocan a mano.
	var monton: Array[Ficha] = p.mazo.fichas.duplicate()
	for m in p.manos:
		monton.append_array(m)
	var sacar := func(clave: String) -> Ficha:
		for f in monton:
			if f.clave() == clave:
				monton.erase(f)
				return f
		return null

	var tu_mano: Array[Ficha] = []
	for clave in TU_MANO:
		tu_mano.append(sacar.call(clave))
	var este: Array[Ficha] = []
	for clave in TE_PASAN + [PRIMER_DESCARTE]:
		este.append(sacar.call(clave))
	var robos: Array[Ficha] = []
	for clave in ROBOS:
		robos.append(sacar.call(clave))

	# El resto de fichas de los rivales: nada que te pueda interesar (ni Nopal ni flores
	# ni lo que se va a robar), para que la historia salga siempre igual.
	var prohibidas := ["flor", "car1", "comodin"] + ROBOS
	var relleno := monton.filter(func(f: Ficha): return not f.clave().begins_with("bam") and not f.clave() in prohibidas)
	var derecha: Array[Ficha] = []
	var enfrente: Array[Ficha] = []
	for i in 13:
		derecha.append(relleno.pop_back())
		enfrente.append(relleno.pop_back())
	while este.size() < 14:
		este.append(relleno.pop_back())
	for f in derecha + enfrente + este:
		monton.erase(f)

	p.manos = [tu_mano, derecha, enfrente, este]
	# El muro: lo que se roba primero va al final (se roba desde el final).
	var muro: Array[Ficha] = monton
	for i in range(robos.size() - 1, -1, -1):
		muro.append(robos[i])
	p.mazo.fichas = muro
	p.turno = ESTE
	return p


## Lo que pasa el jugador de tu izquierda en el Charleston del tutorial.
static func pases_forzados(p: Partida) -> Dictionary:
	var pase: Array[Ficha] = []
	for clave in TE_PASAN:
		for f in p.manos[ESTE]:
			if f.clave() == clave and not pase.has(f):
				pase.append(f)
				break
	return {ESTE: pase}


## Turno de un rival siguiendo el guion: el Este empieza tirando el 4 de Nopal;
## después, cada rival tira la ficha que acaba de robar.
static func turno_rival(p: Partida) -> Dictionary:
	var jugador := p.turno
	var resultado := {"jugador": jugador, "robada": null, "descartada": null, "cambios": 0}
	var ficha: Ficha = null
	if p.total_fichas(jugador) == 14:
		for f in p.manos[jugador]:
			if f.clave() == PRIMER_DESCARTE:
				ficha = f
				break
	else:
		ficha = p.robar()
		resultado["robada"] = ficha
	p.descartar(ficha)
	resultado["descartada"] = ficha
	return resultado
