class_name Asesor
extends RefCounted
## Decide qué fichas "sobran" en una mano.
##
## Lo usan dos partes del juego:
##   - Los rivales controlados por la máquina, para elegir qué pasar o descartar.
##   - El botón «Sugerir», para aconsejar al jugador.
##
## Cómo decide:
##   Mira las 3 manos de la tarjeta más cercanas. Cada ficha recibe puntos según
##   para cuántas de esas manos sirve (más puntos si la mano está más cerca).
##   Las fichas con menos puntos son las que sobran.
##   Los comodines nunca se eligen: ¡son las fichas más valiosas!

const MANOS_A_CONSIDERAR := 3


## Devuelve las `cantidad` fichas que menos sirven (nunca comodines).
## `expuestas` son los grupos que el jugador ya tiene expuestos sobre la mesa.
## `evitar` son claves de fichas peligrosas de soltar (se guardan si se puede).
static func fichas_que_sobran(mano: Array[Ficha], manos_tarjeta: Array[Dictionary], cantidad: int,
		expuestas: Array = [], evitar: Array[String] = []) -> Array[Ficha]:
	var puntos := _puntuar(mano, manos_tarjeta, expuestas)
	for f in mano:
		if f.clave() in evitar:
			puntos[f.id] += 1
	var candidatas: Array[Ficha] = []
	for f in mano:
		if not f.es_comodin():
			candidatas.append(f)
	# Menos puntos primero. Si empatan, se mantiene el orden de la mano.
	candidatas.sort_custom(func(a: Ficha, b: Ficha):
		if puntos[a.id] != puntos[b.id]:
			return puntos[a.id] < puntos[b.id]
		return mano.find(a) < mano.find(b))
	return candidatas.slice(0, cantidad)


## Explica en una frase por qué conviene soltar estas fichas.
static func explicar(fichas: Array[Ficha], mano: Array[Ficha], manos_tarjeta: Array[Dictionary], expuestas: Array = []) -> String:
	var nombres: Array[String] = []
	for f in fichas:
		nombres.append(f.nombre())
	var cercana: Dictionary = Validador.manos_mas_cercanas(mano, manos_tarjeta, 1, expuestas)[0]["mano"]
	var verbo := "ayuda" if fichas.size() == 1 else "ayudan"
	return "Te sugiero soltar: %s. No te %s para «%s», tu mano más cercana." % [
		", ".join(nombres), verbo, cercana["nombre"]]


static func _puntuar(mano: Array[Ficha], manos_tarjeta: Array[Dictionary], expuestas: Array) -> Dictionary:
	var puntos := {}
	for f in mano:
		puntos[f.id] = 0
	var cercanas := Validador.manos_mas_cercanas(mano, manos_tarjeta, MANOS_A_CONSIDERAR, expuestas)
	for i in cercanas.size():
		var peso := MANOS_A_CONSIDERAR - i  # la más cercana vale 3, la siguiente 2...
		if cercanas[i]["faltan"] == Validador.IMPOSIBLE:
			continue
		for id in Validador.ids_utiles(mano, cercanas[i]):
			puntos[id] += peso
	return puntos
