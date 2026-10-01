class_name Tarjeta
extends RefCounted
## La tarjeta de manos ganadoras: «Tarjeta 2026».
##
## IMPORTANTE: la tarjeta oficial de la National Mah Jongg League (NMJL) tiene
## derechos de autor y cambia cada año, así que NO se puede copiar en la app.
## Estas manos son INVENTADAS para este juego, con el mismo estilo que las oficiales
## (secciones por tipo de mano, manos expuestas "X" y ocultas "C").
##
## Cómo se describe una mano:
##   Cada mano es una lista de "grupos". Un grupo es N fichas iguales:
##     1 = suelta, 2 = pareja, 3 = pung, 4 = kong, 5 = quint.
##   Los comodines solo pueden usarse en grupos de 3 o más fichas.
##
##   Los palos se escriben con letras (A, B, C) en lugar de palos fijos:
##   "A" significa "el palo que tú elijas", y letras distintas significan
##   palos distintos. Así una misma mano sirve con Nopal, Picado o Sol.
##
##   Algunos números también son variables: "X" es "el número que tú elijas",
##   y "X+1" es el siguiente. Así se describen las escaleras y los números iguales.
##
## Para añadir una mano: copia una de las de abajo, cambia sus grupos y ejecuta
## las pruebas (comprueban que sume 14 fichas y que se pueda formar).

const TITULO := "Tarjeta 2026"

## Secciones de la tarjeta, en orden.
const SECCIONES := ["2026", "2468", "Números iguales", "Quints", "Escaleras",
	"13579", "Vientos y dragones", "369", "Parejas"]


# --- Funciones de ayuda para escribir grupos de forma cómoda -----------------

## Grupo de números fijos. Ejemplo: num(3, "A", 2) = "222" del palo A.
static func num(cant: int, palo: String, valor: int) -> Dictionary:
	return {"cant": cant, "tipo": "num", "palo": palo, "valor": valor, "relativo": false}


## Grupo de números relativos a X. Ejemplo: num_x(4, "A", 1) = "X+1 X+1 X+1 X+1".
static func num_x(cant: int, palo: String, desplazamiento: int) -> Dictionary:
	return {"cant": cant, "tipo": "num", "palo": palo, "valor": desplazamiento, "relativo": true}


## Grupo de dragones del palo indicado (Nopal -> Maguey, Picado -> Chile, Sol -> Blanco).
## Con letras distintas salen dragones distintos.
static func dragon_de(cant: int, palo: String) -> Dictionary:
	return {"cant": cant, "tipo": "dragon_de", "palo": palo}


## Grupo de un dragón concreto: "R" Chile, "V" Maguey o "B" Blanco.
## El Blanco también hace de "0" en las manos de años (2026).
static func dragon(cant: int, color: String) -> Dictionary:
	return {"cant": cant, "tipo": "dragon", "color": color}


## Grupo de un viento concreto: "N", "E", "O" o "S".
static func viento(cant: int, direccion: String) -> Dictionary:
	return {"cant": cant, "tipo": "viento", "direccion": direccion}


static func flores(cant: int) -> Dictionary:
	return {"cant": cant, "tipo": "flor"}


## Fichas sueltas de un palo. Ejemplo: sueltas("A", [2, 4, 6, 8]) = "2468".
static func sueltas(palo: String, valores: Array) -> Array:
	var grupos := []
	for v in valores:
		grupos.append(num(1, palo, v))
	return grupos


## El año "2026" en fichas sueltas: 2, Blanco (el 0), 2 y 6 del palo indicado.
static func ano(palo: String) -> Array:
	return [num(1, palo, 2), dragon(1, "B"), num(1, palo, 2), num(1, palo, 6)]


## Parejas de un palo. Ejemplo: parejas("A", [1, 3]) = "11 33".
static func parejas(palo: String, valores: Array) -> Array:
	var grupos := []
	for v in valores:
		grupos.append(num(2, palo, v))
	return grupos


## Los 4 vientos sueltos: N, E, O, S.
static func vientos_sueltos() -> Array:
	return [viento(1, "N"), viento(1, "E"), viento(1, "O"), viento(1, "S")]


static func _mano(seccion: String, nombre: String, patron: String, oculta: bool, puntos: int,
		grupos: Array, explicacion: String, consejo: String) -> Dictionary:
	return {
		"seccion": seccion, "nombre": nombre, "patron": patron, "oculta": oculta,
		"puntos": puntos, "grupos": grupos, "explicacion": explicacion, "consejo": consejo,
	}


# --- La tarjeta ---------------------------------------------------------------

static var _cache: Array[Dictionary] = []


## Devuelve todas las manos de la tarjeta. Cada mano suma exactamente 14 fichas.
static func manos() -> Array[Dictionary]:
	if _cache.is_empty():
		_cache = _crear_manos()
	return _cache


static func _crear_manos() -> Array[Dictionary]:
	var X := false  # manos que se pueden exponer
	var C := true   # manos ocultas
	return [
		# ------------------------------------------------------------- 2026
		_mano("2026", "Año 2026", "222 0000 222 6666", X, 25,
			[num(3, "A", 2), dragon(4, "B"), num(3, "B", 2), num(4, "C", 6)],
			"Pungs de 2 en dos palos distintos, kong de Blanco (hace de 0) y kong de 6 en el tercer palo.",
			"El Blanco hace de cero. Cada grupo de números va en un palo diferente."),
		_mano("2026", "2026 con flores", "FF 2026 2222 6666", X, 30,
			[flores(2)] + ano("A") + [num(4, "B", 2), num(4, "B", 6)],
			"Dos flores, el año 2026 en fichas sueltas de un palo y kongs de 2 y de 6 en otro palo.",
			"Las fichas sueltas del 2026 no admiten comodines: consíguelas pronto."),
		_mano("2026", "Vientos del año", "NNN 2026 SSS 2026", X, 30,
			[viento(3, "N")] + ano("A") + [viento(3, "S")] + ano("B"),
			"Pung de Norte, pung de Sur y dos veces el año 2026 en fichas sueltas de dos palos distintos.",
			"Necesitas dos Blancos y cuatro 2: guárdalos desde el Charleston."),
		_mano("2026", "Año con dragones", "2026 DDD DDD FFFF", X, 25,
			ano("A") + [dragon_de(3, "B"), dragon_de(3, "C"), flores(4)],
			"El año 2026 en un palo, pungs de dos dragones distintos y un kong de flores.",
			"Los pungs de dragones y el kong de flores admiten comodines."),
		_mano("2026", "Triple 2026", "FF 2026 2026 2026", C, 50,
			[flores(2)] + ano("A") + ano("B") + ano("C"),
			"Dos flores y el año 2026 en fichas sueltas en los tres palos. Mano oculta.",
			"Todas son sueltas: no admite comodines. Muy difícil, pero vale mucho."),

		# ------------------------------------------------------------- 2468
		_mano("2468", "Pares del 2 al 8", "FF 222 444 666 888", X, 25,
			[flores(2), num(3, "A", 2), num(3, "A", 4), num(3, "A", 6), num(3, "A", 8)],
			"Dos flores y un pung de cada número par, todos del mismo palo.",
			"Guarda los números pares de tu palo más abundante y pasa los impares."),
		_mano("2468", "Pares en dos palos", "22 444 6666 888 FF", X, 25,
			[num(2, "A", 2), num(3, "A", 4), num(4, "B", 6), num(3, "B", 8), flores(2)],
			"Pareja de 2 y pung de 4 en un palo; kong de 6 y pung de 8 en otro; dos flores.",
			"Buena mano si tienes pares repartidos en dos palos."),
		_mano("2468", "Pares con dragón", "FF 2468 DDDD 2468", X, 30,
			[flores(2)] + sueltas("A", [2, 4, 6, 8]) + [dragon_de(4, "C")] + sueltas("B", [2, 4, 6, 8]),
			"Dos flores, 2468 sueltos en dos palos y un kong del dragón del tercer palo.",
			"Las sueltas no admiten comodines; úsalos en el kong de dragón."),
		_mano("2468", "Cuatro, seis, ocho", "FF 444 66 888 DDDD", X, 25,
			[flores(2), num(3, "A", 4), num(2, "A", 6), num(3, "A", 8), dragon_de(4, "A")],
			"Dos flores, 4, 6 y 8 de un palo y un kong del dragón de ese mismo palo.",
			"Maguey va con Nopal, Chile con Picado y Blanco con Sol."),
		_mano("2468", "Kongs 4-6-8", "FF 4444 6666 8888", X, 25,
			[flores(2), num(4, "A", 4), num(4, "B", 6), num(4, "C", 8)],
			"Dos flores y kongs de 4, 6 y 8, cada uno en un palo distinto.",
			"Los kongs admiten comodines: buena mano si tienes varios."),

		# ------------------------------------------------------------- Números iguales
		_mano("Números iguales", "Iguales en tres palos", "FFF XXXX XXX XXXX", X, 25,
			[flores(3), num_x(4, "A", 0), num_x(3, "B", 0), num_x(4, "C", 0)],
			"Tres flores y el mismo número (el que quieras) en los tres palos: kong, pung y kong.",
			"Busca un número del que tengas varias copias en palos distintos."),
		_mano("Números iguales", "Iguales crecientes", "XX XXX XXXX FFFFF", X, 30,
			[num_x(2, "A", 0), num_x(3, "B", 0), num_x(4, "C", 0), flores(5)],
			"El mismo número en tres palos (pareja, pung y kong) y cinco flores.",
			"La pareja no admite comodín; las cinco flores sí."),
		_mano("Números iguales", "Iguales con vientos", "FF XXXX EE XXXX OO", X, 30,
			[flores(2), num_x(4, "A", 0), viento(2, "E"), num_x(4, "B", 0), viento(2, "O")],
			"Dos flores, kongs del mismo número en dos palos y parejas de Este y de Oeste.",
			"Las parejas de vientos no admiten comodín: guárdalas."),
		_mano("Números iguales", "Iguales con dragones", "XXXX DDD XXXX DDD", X, 30,
			[num_x(4, "A", 0), dragon_de(3, "A"), num_x(4, "B", 0), dragon_de(3, "B")],
			"Kongs del mismo número en dos palos, cada uno con un pung de su dragón.",
			"Cada dragón va con su palo: Maguey–Nopal, Chile–Picado, Blanco–Sol."),

		# ------------------------------------------------------------- Quints
		_mano("Quints", "Quints pares", "22222 4444 66666", X, 40,
			[num(5, "A", 2), num(4, "A", 4), num(5, "A", 6)],
			"Quint de 2, kong de 4 y quint de 6, todo del mismo palo.",
			"Un quint son 5 iguales: como solo hay 4 de cada número, necesitas comodines."),
		_mano("Quints", "Quints iguales", "FFFF XXXXX XXXXX", X, 40,
			[flores(4), num_x(5, "A", 0), num_x(5, "B", 0)],
			"Cuatro flores y dos quints del mismo número en dos palos.",
			"Necesitas al menos dos comodines: ¡no los pases nunca!"),
		_mano("Quints", "Quint de viento", "NNNNN DDDD XXXXX", X, 45,
			[viento(5, "N"), dragon(4, "R"), num_x(5, "A", 0)],
			"Quint de Norte, kong de Chile y un quint de cualquier número.",
			"Mano muy valiosa: guarda todos los comodines que puedas."),
		_mano("Quints", "Día de Muertos", "FFFFF XXXX (X+1)(X+1)(X+1)(X+1)(X+1)", X, 40,
			[flores(5), num_x(4, "A", 0), num_x(5, "A", 1)],
			"Cinco cempasúchiles, un kong y un quint de dos números seguidos del mismo palo.",
			"Hay 8 flores en el juego: si te llegan varias, piensa en esta mano."),

		# ------------------------------------------------------------- Escaleras
		_mano("Escaleras", "Escalera de tres", "FF 1111 2222 3333 (seguidos)", X, 25,
			[flores(2), num_x(4, "A", 0), num_x(4, "A", 1), num_x(4, "A", 2)],
			"Dos flores y tres kongs de números seguidos del mismo palo (por ejemplo 3333 4444 5555).",
			"Los kongs admiten comodines: esta mano es buena si tienes varios."),
		_mano("Escaleras", "Escalera creciente", "FFFF 1 22 333 4444 (seguidos)", X, 30,
			[flores(4), num_x(1, "A", 0), num_x(2, "A", 1), num_x(3, "A", 2), num_x(4, "A", 3)],
			"Cuatro flores y cuatro números seguidos de un palo: 1, 2, 3 y 4 copias.",
			"La suelta y la pareja no admiten comodín."),
		_mano("Escaleras", "Escalera doble", "111 2222 111 2222 (seguidos)", X, 25,
			[num_x(3, "A", 0), num_x(4, "A", 1), num_x(3, "B", 0), num_x(4, "B", 1)],
			"Los mismos dos números seguidos en dos palos: pung y kong en cada uno.",
			"Todo son grupos grandes: admite muchos comodines."),
		_mano("Escaleras", "Escalera en tres palos", "FF 1111 2222 3333 (tres palos)", X, 25,
			[flores(2), num_x(4, "A", 0), num_x(4, "B", 1), num_x(4, "C", 2)],
			"Dos flores y tres kongs de números seguidos, cada uno en un palo distinto.",
			"Parecida a «Escalera de tres», pero cambiando de palo en cada kong."),
		_mano("Escaleras", "Escalera con dragón", "111 222 333 DDDDD (seguidos)", X, 30,
			[num_x(3, "A", 0), num_x(3, "A", 1), num_x(3, "A", 2), dragon_de(5, "A")],
			"Tres pungs seguidos de un palo y un quint del dragón de ese palo.",
			"El quint de dragón necesita al menos un comodín."),
		_mano("Escaleras", "Escalera de cuatro", "FF 1234 1111 2222", X, 30,
			[flores(2), num_x(1, "A", 0), num_x(1, "A", 1), num_x(1, "A", 2), num_x(1, "A", 3),
				num_x(4, "B", 0), num_x(4, "B", 1)],
			"Dos flores, cuatro números seguidos sueltos en un palo y kongs de los dos primeros en otro palo.",
			"Ejemplo: 3456 de Nopal con 3333 4444 de Sol."),

		# ------------------------------------------------------------- 13579
		_mano("13579", "Impares", "11 333 5555 777 99", X, 25,
			[num(2, "A", 1), num(3, "A", 3), num(4, "A", 5), num(3, "A", 7), num(2, "A", 9)],
			"Números impares del mismo palo. Las parejas (11 y 99) no admiten comodines.",
			"Consigue pronto las parejas de 1 y de 9: son las únicas sin comodín."),
		_mano("13579", "Impares en dos palos", "1111 333 5555 777", X, 25,
			[num(4, "A", 1), num(3, "A", 3), num(4, "B", 5), num(3, "B", 7)],
			"Kong de 1 y pung de 3 en un palo; kong de 5 y pung de 7 en otro.",
			"Todo son grupos grandes: admite comodines en todos."),
		_mano("13579", "Impares sueltos", "13579 13579 DDDD", X, 30,
			sueltas("A", [1, 3, 5, 7, 9]) + sueltas("B", [1, 3, 5, 7, 9]) + [dragon_de(4, "C")],
			"1, 3, 5, 7 y 9 sueltos en dos palos y un kong del dragón del tercer palo.",
			"Diez fichas sueltas: difícil, pero cualquier impar te sirve al principio."),
		_mano("13579", "Uno, cinco y nueve", "FF 1111 5555 9999", X, 25,
			[flores(2), num(4, "A", 1), num(4, "A", 5), num(4, "A", 9)],
			"Dos flores y kongs de 1, 5 y 9 del mismo palo.",
			"Si tienes los extremos (1 y 9) de un palo, piensa en esta mano."),
		_mano("13579", "Impares del centro", "FF 3333 5555 7777", X, 25,
			[flores(2), num(4, "A", 3), num(4, "B", 5), num(4, "C", 7)],
			"Dos flores y kongs de 3, 5 y 7, cada uno en un palo distinto.",
			"Mezcla de palos: útil cuando no tienes un palo dominante."),

		# ------------------------------------------------------------- Vientos y dragones
		_mano("Vientos y dragones", "Los cuatro vientos", "NNNN EEE OOO SSSS", X, 25,
			[viento(4, "N"), viento(3, "E"), viento(3, "O"), viento(4, "S")],
			"Un kong de Norte, pungs de Este y Oeste y un kong de Sur.",
			"Si al repartir tienes muchos vientos, esta mano es tu mejor opción."),
		_mano("Vientos y dragones", "Tres dragones", "FFF DDDD DDDD DDD", X, 30,
			[flores(3), dragon_de(4, "A"), dragon_de(4, "B"), dragon_de(3, "C")],
			"Tres flores (cempasúchil) y los tres dragones (Chile, Maguey y Blanco): dos kongs y un pung.",
			"Los dragones y las flores suelen descartarse pronto: ¡estate atento para cantarlos!"),
		_mano("Vientos y dragones", "Rosa de los vientos", "FF NN EEE OOO SSSS", X, 25,
			[flores(2), viento(2, "N"), viento(3, "E"), viento(3, "O"), viento(4, "S")],
			"Dos flores y los cuatro vientos: pareja de Norte, pungs de Este y Oeste y kong de Sur.",
			"La pareja de Norte no admite comodín."),
		_mano("Vientos y dragones", "Norte, Sur y dragones", "NNNN SSSS DDD DDD", X, 25,
			[viento(4, "N"), viento(4, "S"), dragon_de(3, "A"), dragon_de(3, "B")],
			"Kongs de Norte y de Sur y pungs de dos dragones distintos.",
			"Todo son grupos grandes: admite comodines en todos."),
		_mano("Vientos y dragones", "Este, Oeste y Chile", "EEEE OOOO DDDDD F", X, 35,
			[viento(4, "E"), viento(4, "O"), dragon(5, "R"), flores(1)],
			"Kongs de Este y de Oeste, quint de Chile y una flor.",
			"¡Picante! El quint de Chile necesita al menos un comodín."),
		_mano("Vientos y dragones", "Vientos y dragones sueltos", "NEOS NEOS DDD DDD", X, 30,
			vientos_sueltos() + vientos_sueltos() + [dragon_de(3, "A"), dragon_de(3, "B")],
			"Dos veces los cuatro vientos sueltos y pungs de dos dragones distintos.",
			"Los vientos sueltos no admiten comodines."),
		_mano("Vientos y dragones", "Pungs de vientos", "FF NNN EEE OOO SSS", X, 25,
			[flores(2), viento(3, "N"), viento(3, "E"), viento(3, "O"), viento(3, "S")],
			"Dos flores y un pung de cada viento.",
			"Cuatro pungs: todos admiten comodines."),

		# ------------------------------------------------------------- 369
		_mano("369", "Tres, seis, nueve", "333 666 9999 FFFF", X, 25,
			[num(3, "A", 3), num(3, "A", 6), num(4, "A", 9), flores(4)],
			"Pungs de 3 y 6, kong de 9 del mismo palo y cuatro flores.",
			"Fácil de reconocer: solo múltiplos de 3."),
		_mano("369", "369 con dragón", "3333 66 9999 DDDD", X, 30,
			[num(4, "A", 3), num(2, "A", 6), num(4, "A", 9), dragon_de(4, "B")],
			"Kongs de 3 y 9 y pareja de 6 en un palo, y un kong del dragón de otro palo.",
			"El dragón NO es el del mismo palo: mira la sección de dragones en «Reglas»."),
		_mano("369", "369 en tres palos", "FFF 3333 666 9999", X, 25,
			[flores(3), num(4, "A", 3), num(3, "B", 6), num(4, "C", 9)],
			"Tres flores y 3, 6 y 9, cada uno en un palo distinto.",
			"Útil cuando tus múltiplos de 3 están repartidos."),
		_mano("369", "369 en parejas y pungs", "33 66 99 333 666 99", X, 30,
			[num(2, "A", 3), num(2, "A", 6), num(2, "A", 9), num(3, "B", 3), num(3, "B", 6), num(2, "B", 9)],
			"Parejas de 3, 6 y 9 en un palo; pungs de 3 y 6 y pareja de 9 en otro.",
			"Muchas parejas: pocos comodines sirven aquí."),

		# ------------------------------------------------------------- Parejas (ocultas)
		_mano("Parejas", "Parejas en escalera", "11 22 33 44 55 66 77 (seguidas)", C, 50,
			[num_x(2, "A", 0), num_x(2, "A", 1), num_x(2, "A", 2), num_x(2, "A", 3),
				num_x(2, "A", 4), num_x(2, "A", 5), num_x(2, "A", 6)],
			"Siete parejas de números seguidos del mismo palo. Mano oculta: no puedes cantar descartes.",
			"Solo son parejas, así que NO admite comodines. Es difícil: mejor para expertos."),
		_mano("Parejas", "Parejas de vientos y dragones", "NN EE OO SS DD DD DD", C, 50,
			[viento(2, "N"), viento(2, "E"), viento(2, "O"), viento(2, "S"),
				dragon_de(2, "A"), dragon_de(2, "B"), dragon_de(2, "C")],
			"Una pareja de cada viento y de cada dragón. Mano oculta.",
			"Sin comodines. Guarda las parejas de vientos y dragones que te lleguen."),
		_mano("Parejas", "Parejas en espejo", "FF 11 22 33 11 22 33", C, 50,
			[flores(2)] + parejas("A", [1, 2, 3]) + parejas("B", [1, 2, 3]),
			"Dos flores y parejas de 1, 2 y 3 en dos palos, como en un espejo. Mano oculta.",
			"Sin comodines: necesitas dos copias de 1, 2 y 3 en dos palos distintos."),
		_mano("Parejas", "Parejas impares", "11 33 55 77 99 DD FF", C, 50,
			parejas("A", [1, 3, 5, 7, 9]) + [dragon_de(2, "A"), flores(2)],
			"Parejas de todos los impares de un palo, pareja de su dragón y dos flores. Mano oculta.",
			"Sin comodines: necesitas dos copias de cada impar."),
		_mano("Parejas", "Parejas pares", "FF 22 44 66 88 22 44", C, 50,
			[flores(2)] + parejas("A", [2, 4, 6, 8]) + parejas("B", [2, 4]),
			"Dos flores, parejas de todos los pares de un palo y parejas de 2 y 4 en otro. Mano oculta.",
			"Sin comodines: necesitas dos copias de cada par."),
	]


## Un ejemplo concreto de la mano (con los palos A = Nopal, B = Picado, C = Sol y X = 1),
## separado en grupos. Usa fichas reales y solo pone comodines donde hacen falta
## (por ejemplo, en un quint). Sirve para dibujar la tarjeta.
## Con `variante` se dibuja esa variante concreta (por ejemplo, la más cercana a tus fichas).
static func ejemplo(mano: Dictionary, variante: Dictionary = {}) -> Array:
	if variante.is_empty():
		variante = Validador.variantes(mano)[0]
	var usadas := {}
	var id := 10000
	var resultado := []
	for g in variante["grupos"]:
		var clave: String = g["clave"]
		var maximo := 8 if clave == "flor" else 4
		var naturales := mini(g["cant"], maximo - usadas.get(clave, 0))
		usadas[clave] = usadas.get(clave, 0) + naturales
		var grupo: Array[Ficha] = []
		for i in g["cant"]:
			if i < naturales:
				grupo.append(Ficha.desde_clave(clave, id))
			else:
				grupo.append(Ficha.new(Ficha.Tipo.COMODIN, "", 0, id))
			id += 1
		resultado.append(grupo)
	return resultado


## Como `ejemplo`, pero con la variante más cercana a TUS fichas y marcando cuáles ya tienes.
## Devuelve una lista de grupos; cada ficha es {"ficha": Ficha, "tienes": bool}.
## Los huecos que cubren tus comodines se dibujan con un comodín.
## Las fichas marcadas suman siempre 14 menos las que te faltan (como el validador).
static func ejemplo_con_tus_fichas(mano: Dictionary, fichas: Array[Ficha], expuestas: Array = []) -> Array:
	var analisis := Validador.analizar(fichas, mano, expuestas)
	var variante: Dictionary = analisis.get("variante", {})
	var resultado := []
	for g in ejemplo(mano, variante):
		var grupo := []
		for f in g:
			grupo.append({"ficha": f, "tienes": false})
		resultado.append(grupo)
	if analisis["faltan"] == Validador.IMPOSIBLE:
		return resultado
	var grupos: Array = variante["grupos"]

	# 1. Tus grupos expuestos ya son tuyos.
	var libres: Array[int] = []
	for i in grupos.size():
		libres.append(i)
	for e in expuestas:
		for i in libres:
			if grupos[i]["clave"] == e["clave"] and grupos[i]["cant"] == e["fichas"].size():
				for k in grupos[i]["cant"]:
					resultado[i][k] = {"ficha": e["fichas"][k], "tienes": true}
				libres.erase(i)
				break

	# 2. Tus fichas: primero en parejas y sueltas (no admiten comodín), luego en grupos de 3 o más.
	var c := Validador.contar(fichas)
	var conteo: Dictionary = c["conteo"].duplicate()
	for grandes in [false, true]:
		for i in libres:
			var clave: String = grupos[i]["clave"]
			if (grupos[i]["cant"] >= 3) != grandes:
				continue
			for k in grupos[i]["cant"]:
				if conteo.get(clave, 0) > 0:
					conteo[clave] -= 1
					resultado[i][k] = {"ficha": Ficha.desde_clave(clave), "tienes": true}

	# 3. Tus comodines, en los huecos de los grupos de 3 o más.
	var comodines: int = c["comodines"]
	for i in libres:
		if grupos[i]["cant"] < 3:
			continue
		for k in grupos[i]["cant"]:
			if comodines > 0 and not resultado[i][k]["tienes"]:
				comodines -= 1
				resultado[i][k] = {"ficha": Ficha.desde_clave("comodin"), "tienes": true}
	return resultado
