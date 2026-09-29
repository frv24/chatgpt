class_name Validador
extends RefCounted
## Comprueba si una mano de fichas cumple una mano de la tarjeta, y calcula
## cuántas fichas faltan (esto se usa para los consejos al jugador).
##
## Idea general:
##   1. Una mano de la tarjeta tiene variables (palos A/B/C y el número X).
##      Probamos todas las combinaciones posibles; a cada una la llamamos "variante".
##      Ejemplo: "222 444 666 888 del palo A" tiene 3 variantes (bambúes,
##      caracteres o círculos).
##   2. Cada variante es una lista concreta de fichas necesarias, separadas en:
##        - "solo_naturales": fichas de parejas o sueltas (sin comodín).
##        - "con_comodin": fichas de grupos de 3 o más (el comodín vale).
##   3. Comparamos lo que tiene el jugador con cada variante y nos quedamos
##      con la que está más cerca.


## Devuelve todas las variantes concretas de una mano de la tarjeta.
## Cada variante es un Dictionary: clave de ficha -> {"solo_naturales": n, "con_comodin": n}
static func variantes(mano_tarjeta: Dictionary) -> Array[Dictionary]:
	var grupos: Array = mano_tarjeta["grupos"]

	# ¿Qué letras de palo usa la mano? (A, B, C...)
	var letras: Array[String] = []
	var usa_x := false
	var max_desplazamiento := 0
	for g in grupos:
		if g.has("palo") and not letras.has(g["palo"]):
			letras.append(g["palo"])
		if g.get("relativo", false):
			usa_x = true
			max_desplazamiento = maxi(max_desplazamiento, g["valor"])
	letras.sort()

	# Valores posibles de X: el número más alto (X + desplazamiento) no puede pasar de 9.
	var valores_x: Array[int] = [0]
	if usa_x:
		valores_x.clear()
		for x in range(1, 10 - max_desplazamiento):
			valores_x.append(x)

	var resultado: Array[Dictionary] = []
	for asignacion in _asignaciones_de_palos(letras):
		for x in valores_x:
			resultado.append(_concretar(grupos, asignacion, x))
	return resultado


## Todas las formas de dar un palo distinto a cada letra.
## Ejemplo con ["A", "B"]: {A: bam, B: car}, {A: bam, B: cir}, {A: car, B: bam}...
static func _asignaciones_de_palos(letras: Array[String]) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	_asignar(letras, 0, {}, resultado)
	return resultado


static func _asignar(letras: Array[String], i: int, actual: Dictionary, resultado: Array[Dictionary]) -> void:
	if i == letras.size():
		resultado.append(actual.duplicate())
		return
	for palo in Ficha.PALOS:
		if palo in actual.values():
			continue
		actual[letras[i]] = palo
		_asignar(letras, i + 1, actual, resultado)
		actual.erase(letras[i])


static func _concretar(grupos: Array, asignacion: Dictionary, x: int) -> Dictionary:
	var req := {}
	for g in grupos:
		var clave := ""
		match g["tipo"]:
			"num":
				var valor: int = g["valor"] + (x if g["relativo"] else 0)
				clave = asignacion[g["palo"]] + str(valor)
			"dragon_de":
				clave = "d" + Ficha.DRAGON_DEL_PALO[asignacion[g["palo"]]]
			"dragon":
				clave = "d" + g["color"]
			"viento":
				clave = "v" + g["direccion"]
			"flor":
				clave = "flor"
		if not req.has(clave):
			req[clave] = {"solo_naturales": 0, "con_comodin": 0}
		# Regla del Mahjong americano: comodines solo en grupos de 3 o más.
		if g["cant"] >= 3:
			req[clave]["con_comodin"] += g["cant"]
		else:
			req[clave]["solo_naturales"] += g["cant"]
	return req


## Cuenta cuántas fichas hay de cada clave. Los comodines van aparte.
static func contar(fichas: Array[Ficha]) -> Dictionary:
	var conteo := {}
	var comodines := 0
	for f in fichas:
		if f.es_comodin():
			comodines += 1
		else:
			conteo[f.clave()] = conteo.get(f.clave(), 0) + 1
	return {"conteo": conteo, "comodines": comodines}


## Compara las fichas del jugador con una variante concreta.
## Devuelve:
##   "faltan": cuántas fichas le faltan para completarla (0 = completa).
##   "utiles": clave -> cuántas fichas de esa clave sirven para esta variante.
##   "comodines_usados": cuántos comodines del jugador se aprovechan.
static func _comparar(conteo: Dictionary, comodines: int, req: Dictionary) -> Dictionary:
	var faltan_naturales := 0
	var faltan_comodinables := 0
	var utiles := {}
	for clave in req:
		var tengo: int = conteo.get(clave, 0)
		var p: int = req[clave]["solo_naturales"]
		var q: int = req[clave]["con_comodin"]
		# Primero se cubren las parejas/sueltas, que no admiten comodín.
		var usadas_p := mini(tengo, p)
		var usadas_q := mini(tengo - usadas_p, q)
		faltan_naturales += p - usadas_p
		faltan_comodinables += q - usadas_q
		if usadas_p + usadas_q > 0:
			utiles[clave] = usadas_p + usadas_q
	var comodines_usados := mini(comodines, faltan_comodinables)
	return {
		"faltan": faltan_naturales + faltan_comodinables - comodines_usados,
		"utiles": utiles,
		"comodines_usados": comodines_usados,
	}


## Analiza unas fichas contra una mano de la tarjeta y devuelve la variante más cercana
## (el resultado de _comparar más la variante elegida en "variante").
static func analizar(fichas: Array[Ficha], mano_tarjeta: Dictionary) -> Dictionary:
	var c := contar(fichas)
	var mejor := {}
	for req in variantes(mano_tarjeta):
		var r := _comparar(c["conteo"], c["comodines"], req)
		if mejor.is_empty() or r["faltan"] < mejor["faltan"]:
			mejor = r
			mejor["variante"] = req
	return mejor


## ¿Estas 14 fichas forman exactamente esta mano de la tarjeta?
static func es_mano_ganadora(fichas: Array[Ficha], mano_tarjeta: Dictionary) -> bool:
	# Todas las manos suman 14; si no faltan fichas, las 14 están usadas y no sobra ninguna.
	return fichas.size() == 14 and analizar(fichas, mano_tarjeta)["faltan"] == 0


## Devuelve la primera mano de la tarjeta que cumplen las fichas, o {} si ninguna.
static func buscar_mano_ganadora(fichas: Array[Ficha], manos: Array[Dictionary]) -> Dictionary:
	for mano in manos:
		if es_mano_ganadora(fichas, mano):
			return mano
	return {}


## Ordena las manos de la tarjeta de la más cercana a la más lejana.
## Cada elemento: {"mano": Dictionary, "faltan": int, "utiles": Dictionary, ...}
static func manos_mas_cercanas(fichas: Array[Ficha], manos: Array[Dictionary], cuantas: int = 3) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for mano in manos:
		var r := analizar(fichas, mano)
		r["mano"] = mano
		lista.append(r)
	lista.sort_custom(func(a, b): return a["faltan"] < b["faltan"])
	return lista.slice(0, cuantas)


## Dado un análisis, marca qué fichas concretas de la mano son útiles.
## Devuelve un Array de ids de fichas útiles. Los comodines siempre son útiles.
static func ids_utiles(fichas: Array[Ficha], analisis: Dictionary) -> Array[int]:
	var restantes: Dictionary = analisis["utiles"].duplicate()
	var ids: Array[int] = []
	for f in fichas:
		if f.es_comodin():
			ids.append(f.id)
		elif restantes.get(f.clave(), 0) > 0:
			restantes[f.clave()] -= 1
			ids.append(f.id)
	return ids
