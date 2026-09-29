class_name Mazo
extends RefCounted
## El conjunto de las 152 fichas: se crea, se baraja y se reparte desde aquí.

const TOTAL_FICHAS := 152

var fichas: Array[Ficha] = []
var _rng := RandomNumberGenerator.new()


## Crea el mazo completo. Si pasas una semilla distinta de 0, el barajado
## sale siempre igual (útil para pruebas y para repetir una partida).
func _init(semilla: int = 0) -> void:
	if semilla != 0:
		_rng.seed = semilla
	else:
		_rng.randomize()
	_crear_fichas()


func _crear_fichas() -> void:
	fichas.clear()
	var id := 0
	# 4 copias de cada ficha "normal".
	for _copia in 4:
		for palo in Ficha.PALOS:
			for valor in range(1, 10):
				fichas.append(Ficha.new(Ficha.Tipo.NUMERO, palo, valor, id))
				id += 1
		for viento in ["N", "E", "O", "S"]:
			fichas.append(Ficha.new(Ficha.Tipo.VIENTO, viento, 0, id))
			id += 1
		for dragon in ["R", "V", "B"]:
			fichas.append(Ficha.new(Ficha.Tipo.DRAGON, dragon, 0, id))
			id += 1
	# 8 flores y 8 comodines.
	for _i in 8:
		fichas.append(Ficha.new(Ficha.Tipo.FLOR, "", 0, id))
		id += 1
	for _i in 8:
		fichas.append(Ficha.new(Ficha.Tipo.COMODIN, "", 0, id))
		id += 1


## Baraja con el algoritmo de Fisher-Yates (cada orden es igual de probable).
func barajar() -> void:
	for i in range(fichas.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := fichas[i]
		fichas[i] = fichas[j]
		fichas[j] = tmp


func quedan() -> int:
	return fichas.size()


## Saca una ficha del mazo. Devuelve null si ya no quedan.
func robar() -> Ficha:
	if fichas.is_empty():
		return null
	return fichas.pop_back()


## Saca varias fichas de golpe (por ejemplo, las 13 del reparto inicial).
func repartir(cantidad: int) -> Array[Ficha]:
	var mano: Array[Ficha] = []
	for _i in cantidad:
		var f := robar()
		if f == null:
			break
		mano.append(f)
	return mano
