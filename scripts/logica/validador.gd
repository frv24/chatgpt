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
##   2. Cada variante es una lista concreta de grupos: {"clave": "bam2", "cant": 3}...
##   3. Los grupos EXPUESTOS (los que el jugador ya enseñó al cantar un descarte)
##      tienen que coincidir con un grupo de la variante. Las manos ocultas no
##      admiten grupos expuestos.
##   4. El resto de grupos se compara con las fichas de la mano:
##        - "solo_naturales": fichas de parejas o sueltas (sin comodín).
##        - "con_comodin": fichas de grupos de 3 o más (el comodín vale).
##   5. Nos quedamos con la variante que está más cerca.
##
## Un grupo expuesto es un Dictionary: {"clave": "bam2", "fichas": Array[Ficha]}.

## Valor de "faltan" cuando una mano ya no se puede conseguir.
const IMPOSIBLE := 99


## Variantes ya calculadas, por nombre de mano (se calculan una sola vez).
static var _cache_variantes := {}


## Devuelve todas las variantes concretas de una mano de la tarjeta.
## Cada variante es {"grupos": [{"clave": String, "cant": int}, ...], "req": requisitos}.
static func variantes(mano_tarjeta: Dictionary) -> Array[Dictionary]:
	var nombre: String = mano_tarjeta["nombre"]
	if not _cache_variantes.has(nombre):
		_cache_variantes[nombre] = _calcular_variantes(mano_tarjeta)
	return _cache_variantes[nombre]


static func _calcular_variantes(mano_tarjeta: Dictionary) -> Array[Dictionary]:
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
	var vistas := {}
	for asignacion in _asignaciones_de_palos(letras):
		for x in valores_x:
			var variante := {"grupos": _concretar(grupos, asignacion, x)}
			variante["req"] = _requisitos_ocultos(variante, [])
			# Algunas asignaciones dan la misma variante (por ejemplo, dragones de
			# palos distintos en otro orden): solo se guarda una vez.
			var firma := str(variante["req"])
			if not vistas.has(firma):
				vistas[firma] = true
				resultado.append(variante)
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


## Convierte los grupos de la tarjeta (con letras y X) en grupos concretos.
static func _concretar(grupos: Array, asignacion: Dictionary, x: int) -> Array:
	var concretos := []
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
		concretos.append({"clave": clave, "cant": g["cant"]})
	return concretos


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


## Quita de la variante los grupos que ya están expuestos y devuelve lo que falta
## por completar con la mano, agrupado por clave. Devuelve {} si algún grupo
## expuesto no encaja en esta variante.
static func _requisitos_ocultos(variante: Dictionary, expuestas: Array) -> Dictionary:
	var libres: Array = variante["grupos"].duplicate()
	for e in expuestas:
		var encontrado := -1
		for i in libres.size():
			if libres[i]["clave"] == e["clave"] and libres[i]["cant"] == e["fichas"].size():
				encontrado = i
				break
		if encontrado == -1:
			return {}
		libres.remove_at(encontrado)

	var req := {}
	for g in libres:
		if not req.has(g["clave"]):
			req[g["clave"]] = {"solo_naturales": 0, "con_comodin": 0}
		# Regla del Mahjong americano: comodines solo en grupos de 3 o más.
		if g["cant"] >= 3:
			req[g["clave"]]["con_comodin"] += g["cant"]
		else:
			req[g["clave"]]["solo_naturales"] += g["cant"]
	# Marca para distinguir "no encaja" de "no falta nada".
	req["_ok"] = true
	return req


## Compara las fichas del jugador con los requisitos de una variante.
## Devuelve:
##   "faltan": cuántas fichas le faltan para completarla (0 = completa).
##   "utiles": clave -> cuántas fichas de esa clave sirven para esta variante.
##   "comodines_usados": cuántos comodines del jugador se aprovechan.
static func _comparar(conteo: Dictionary, comodines: int, req: Dictionary) -> Dictionary:
	var faltan_naturales := 0
	var faltan_comodinables := 0
	var utiles := {}
	for clave in req:
		if clave == "_ok":
			continue
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


## Analiza unas fichas (y los grupos expuestos del jugador) contra una mano de la
## tarjeta y devuelve la variante más cercana. Si la mano ya no es posible
## (por ejemplo, es oculta y el jugador tiene grupos expuestos), "faltan" vale IMPOSIBLE.
static func analizar(fichas: Array[Ficha], mano_tarjeta: Dictionary, expuestas: Array = []) -> Dictionary:
	var mejor := {"faltan": IMPOSIBLE, "utiles": {}, "comodines_usados": 0}
	if mano_tarjeta["oculta"] and not expuestas.is_empty():
		return mejor
	var c := contar(fichas)
	for variante in variantes(mano_tarjeta):
		var req: Dictionary = variante["req"] if expuestas.is_empty() else _requisitos_ocultos(variante, expuestas)
		if req.is_empty():
			continue
		var r := _comparar(c["conteo"], c["comodines"], req)
		if r["faltan"] < mejor["faltan"]:
			mejor = r
			mejor["variante"] = variante
			mejor["req"] = req
	return mejor


## Qué fichas concretas te faltan para una mano de la tarjeta (con su mejor variante).
## Devuelve una lista de claves (repetidas si faltan varias iguales), sin contar
## las que ya pueden cubrir tus comodines. Su tamaño es igual a "faltan".
## Primero van las que solo valen de verdad (parejas y sueltas, sin comodín).
static func fichas_que_faltan(fichas: Array[Ficha], mano_tarjeta: Dictionary, expuestas: Array = []) -> Array[String]:
	var faltantes: Array[String] = []
	var analisis := analizar(fichas, mano_tarjeta, expuestas)
	if analisis["faltan"] == IMPOSIBLE:
		return faltantes
	var c := contar(fichas)
	var req: Dictionary = analisis["req"]
	var comodinables: Array[String] = []
	for clave in req:
		if clave == "_ok":
			continue
		var tengo: int = c["conteo"].get(clave, 0)
		var p: int = req[clave]["solo_naturales"]
		var q: int = req[clave]["con_comodin"]
		var usadas_p := mini(tengo, p)
		for i in p - usadas_p:
			faltantes.append(clave)
		for i in maxi(0, q - (tengo - usadas_p)):
			comodinables.append(clave)
	# Tus comodines cubren parte de los grupos de 3 o más.
	comodinables.resize(maxi(0, comodinables.size() - c["comodines"]))
	faltantes.append_array(comodinables)
	return faltantes


## ¿Estas fichas (más los grupos expuestos) forman exactamente esta mano de la tarjeta?
static func es_mano_ganadora(fichas: Array[Ficha], mano_tarjeta: Dictionary, expuestas: Array = []) -> bool:
	var total := fichas.size()
	for e in expuestas:
		total += e["fichas"].size()
	# Todas las manos suman 14; si no faltan fichas, las 14 están usadas y no sobra ninguna.
	return total == 14 and analizar(fichas, mano_tarjeta, expuestas)["faltan"] == 0


## Devuelve la primera mano de la tarjeta que cumplen las fichas, o {} si ninguna.
static func buscar_mano_ganadora(fichas: Array[Ficha], manos: Array[Dictionary], expuestas: Array = []) -> Dictionary:
	for mano in manos:
		if es_mano_ganadora(fichas, mano, expuestas):
			return mano
	return {}


## Ordena las manos de la tarjeta de la más cercana a la más lejana.
## Cada elemento: {"mano": Dictionary, "faltan": int, "utiles": Dictionary, ...}
static func manos_mas_cercanas(fichas: Array[Ficha], manos: Array[Dictionary], cuantas: int = 3, expuestas: Array = []) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for mano in manos:
		var r := analizar(fichas, mano, expuestas)
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
