class_name Tarjeta
extends RefCounted
## La tarjeta de manos ganadoras.
##
## IMPORTANTE: la tarjeta oficial de la National Mah Jongg League (NMJL) tiene
## derechos de autor y cambia cada año, así que NO se puede copiar en la app.
## Estas manos son INVENTADAS para este juego ("Tarjeta de principiante"),
## con el mismo estilo que las oficiales.
##
## Cómo se describe una mano:
##   Cada mano es una lista de "grupos". Un grupo es N fichas iguales:
##     1 = suelta, 2 = pareja, 3 = pung, 4 = kong, 5 = quint.
##   Los comodines solo pueden usarse en grupos de 3 o más fichas.
##
##   Los palos se escriben con letras (A, B, C) en lugar de palos fijos:
##   "A" significa "el palo que tú elijas", y letras distintas significan
##   palos distintos. Así una misma mano sirve con bambúes, caracteres o círculos.
##
##   Algunos números también son variables: "X" es "el número que tú elijas",
##   y "X+1" es el siguiente. Así se describen las escaleras.


# --- Funciones de ayuda para escribir grupos de forma cómoda -----------------

## Grupo de números fijos. Ejemplo: num(3, "A", 2) = "222" del palo A.
static func num(cant: int, palo: String, valor: int) -> Dictionary:
	return {"cant": cant, "tipo": "num", "palo": palo, "valor": valor, "relativo": false}


## Grupo de números relativos a X. Ejemplo: num_x(4, "A", 1) = "X+1 X+1 X+1 X+1".
static func num_x(cant: int, palo: String, desplazamiento: int) -> Dictionary:
	return {"cant": cant, "tipo": "num", "palo": palo, "valor": desplazamiento, "relativo": true}


## Grupo de dragones del mismo color que el palo indicado
## (bambú -> verde, carácter -> rojo, círculo -> blanco).
static func dragon_de(cant: int, palo: String) -> Dictionary:
	return {"cant": cant, "tipo": "dragon_de", "palo": palo}


## Grupo de un dragón concreto: "R" rojo, "V" verde o "B" blanco.
## El dragón blanco también hace de "0" en las manos de años (2026).
static func dragon(cant: int, color: String) -> Dictionary:
	return {"cant": cant, "tipo": "dragon", "color": color}


## Grupo de un viento concreto: "N", "E", "O" o "S".
static func viento(cant: int, direccion: String) -> Dictionary:
	return {"cant": cant, "tipo": "viento", "direccion": direccion}


static func flores(cant: int) -> Dictionary:
	return {"cant": cant, "tipo": "flor"}


# --- La tarjeta ---------------------------------------------------------------

## Devuelve todas las manos de la tarjeta de principiante.
## Cada mano suma exactamente 14 fichas.
static func manos() -> Array[Dictionary]:
	return [
		{
			"nombre": "Pares del 2 al 8",
			"patron": "FF 222 444 666 888",
			"explicacion": "Dos flores y un pung de cada número par, todos del mismo palo.",
			"consejo": "Guarda los números pares de tu palo más abundante y pasa los impares.",
			"oculta": false,
			"puntos": 25,
			"grupos": [flores(2), num(3, "A", 2), num(3, "A", 4), num(3, "A", 6), num(3, "A", 8)],
		},
		{
			"nombre": "Impares",
			"patron": "11 333 5555 777 99",
			"explicacion": "Números impares del mismo palo. Las parejas (11 y 99) no admiten comodines.",
			"consejo": "Consigue pronto las parejas de 1 y de 9: son las únicas sin comodín.",
			"oculta": false,
			"puntos": 25,
			"grupos": [num(2, "A", 1), num(3, "A", 3), num(4, "A", 5), num(3, "A", 7), num(2, "A", 9)],
		},
		{
			"nombre": "Escalera de tres",
			"patron": "FF 1111 2222 3333 (seguidos)",
			"explicacion": "Dos flores y tres kongs de números seguidos del mismo palo (por ejemplo 3333 4444 5555).",
			"consejo": "Los kongs admiten comodines: esta mano es buena si tienes varios.",
			"oculta": false,
			"puntos": 25,
			"grupos": [flores(2), num_x(4, "A", 0), num_x(4, "A", 1), num_x(4, "A", 2)],
		},
		{
			"nombre": "Los cuatro vientos",
			"patron": "NNNN EEE OOO SSSS",
			"explicacion": "Un kong de Norte, pungs de Este y Oeste y un kong de Sur.",
			"consejo": "Si al repartir tienes muchos vientos, esta mano es tu mejor opción.",
			"oculta": false,
			"puntos": 25,
			"grupos": [viento(4, "N"), viento(3, "E"), viento(3, "O"), viento(4, "S")],
		},
		{
			"nombre": "Año 2026",
			"patron": "222 0000 222 6666",
			"explicacion": "Pungs de 2 en dos palos distintos, kong de dragón blanco (hace de 0) y kong de 6 en el tercer palo.",
			"consejo": "El dragón blanco hace de cero. Cada grupo de números va en un palo diferente.",
			"oculta": false,
			"puntos": 25,
			"grupos": [num(3, "A", 2), dragon(4, "B"), num(3, "B", 2), num(4, "C", 6)],
		},
		{
			"nombre": "Parejas en escalera",
			"patron": "11 22 33 44 55 66 77 (seguidas)",
			"explicacion": "Siete parejas de números seguidos del mismo palo. Mano oculta: no puedes cantar descartes.",
			"consejo": "Solo son parejas, así que NO admite comodines. Es difícil: mejor para expertos.",
			"oculta": true,
			"puntos": 50,
			"grupos": [
				num_x(2, "A", 0), num_x(2, "A", 1), num_x(2, "A", 2), num_x(2, "A", 3),
				num_x(2, "A", 4), num_x(2, "A", 5), num_x(2, "A", 6),
			],
		},
		{
			"nombre": "Tres dragones",
			"patron": "FFF DDDD DDDD DDD",
			"explicacion": "Tres flores y los tres dragones: dos kongs y un pung.",
			"consejo": "Los dragones y las flores suelen descartarse pronto: ¡estate atento para cantarlos!",
			"oculta": false,
			"puntos": 30,
			"grupos": [flores(3), dragon_de(4, "A"), dragon_de(4, "B"), dragon_de(3, "C")],
		},
	]
