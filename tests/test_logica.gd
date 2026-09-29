extends SceneTree
## Pruebas automáticas de la lógica del juego (sin gráficos).
##
## Cómo ejecutarlas desde la terminal, en la carpeta del proyecto:
##   godot --headless --import
##   godot --headless --script res://tests/test_logica.gd
##
## Si todo va bien, termina con "TODAS LAS PRUEBAS PASARON".

var _fallos := 0
var _pruebas := 0


func _init() -> void:
	probar_mazo()
	probar_tarjeta()
	probar_manos_ganadoras()
	probar_comodines()
	probar_consejos()

	print("")
	if _fallos == 0:
		print("TODAS LAS PRUEBAS PASARON (%d)" % _pruebas)
	else:
		print("FALLARON %d de %d pruebas" % [_fallos, _pruebas])
	quit(1 if _fallos > 0 else 0)


func comprobar(condicion: bool, descripcion: String) -> void:
	_pruebas += 1
	if condicion:
		print("  ok   ", descripcion)
	else:
		_fallos += 1
		print("  FALLO ", descripcion)


## Crea fichas a partir de un texto. Ejemplo: "flor flor bam2 bam2 comodin vN dB".
func fichas(texto: String) -> Array[Ficha]:
	var resultado: Array[Ficha] = []
	var id := 1000
	for clave in texto.split(" ", false):
		var f: Ficha
		if clave == "flor":
			f = Ficha.new(Ficha.Tipo.FLOR, "", 0, id)
		elif clave == "comodin":
			f = Ficha.new(Ficha.Tipo.COMODIN, "", 0, id)
		elif clave.begins_with("v"):
			f = Ficha.new(Ficha.Tipo.VIENTO, clave.substr(1), 0, id)
		elif clave.begins_with("d"):
			f = Ficha.new(Ficha.Tipo.DRAGON, clave.substr(1), 0, id)
		else:
			f = Ficha.new(Ficha.Tipo.NUMERO, clave.substr(0, 3), int(clave.substr(3)), id)
		assert(f.clave() == clave, "Clave mal escrita en la prueba: " + clave)
		resultado.append(f)
		id += 1
	return resultado


func mano(nombre: String) -> Dictionary:
	for m in Tarjeta.manos():
		if m["nombre"] == nombre:
			return m
	push_error("No existe la mano " + nombre)
	return {}


func probar_mazo() -> void:
	print("Mazo:")
	var mazo := Mazo.new(12345)
	comprobar(mazo.quedan() == 152, "el mazo tiene 152 fichas")
	var c := Validador.contar(mazo.fichas)
	comprobar(c["comodines"] == 8, "hay 8 comodines")
	comprobar(c["conteo"]["flor"] == 8, "hay 8 flores")
	comprobar(c["conteo"]["bam5"] == 4, "hay 4 copias de bambú 5")
	comprobar(c["conteo"]["dB"] == 4, "hay 4 dragones blancos")
	var ids := {}
	for f in mazo.fichas:
		ids[f.id] = true
	comprobar(ids.size() == 152, "cada ficha tiene un id distinto")

	mazo.barajar()
	var otro := Mazo.new(12345)
	otro.barajar()
	comprobar(mazo.fichas[0].id == otro.fichas[0].id, "la misma semilla baraja igual")
	var mano_inicial := mazo.repartir(13)
	comprobar(mano_inicial.size() == 13 and mazo.quedan() == 139, "repartir 13 deja 139 en el mazo")


func probar_tarjeta() -> void:
	print("Tarjeta:")
	for m in Tarjeta.manos():
		var total := 0
		for g in m["grupos"]:
			total += g["cant"]
		comprobar(total == 14, "'%s' suma 14 fichas" % m["nombre"])
	comprobar(Validador.variantes(mano("Pares del 2 al 8")).size() == 3, "una mano de un palo tiene 3 variantes")
	comprobar(Validador.variantes(mano("Escalera de tres")).size() == 21, "escalera: 3 palos x 7 valores de X")


func probar_manos_ganadoras() -> void:
	print("Manos ganadoras:")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8 car8"),
		mano("Pares del 2 al 8")), "pares del 2 al 8 en caracteres")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 bam8 bam8 bam8"),
		mano("Pares del 2 al 8")), "pares mezclando palos NO vale")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor cir5 cir5 cir5 cir5 cir6 cir6 cir6 cir6 cir7 cir7 cir7 cir7"),
		mano("Escalera de tres")), "escalera 5-6-7 en círculos")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor flor cir5 cir5 cir5 cir5 cir6 cir6 cir6 cir6 cir8 cir8 cir8 cir8"),
		mano("Escalera de tres")), "escalera con un hueco NO vale")
	comprobar(Validador.es_mano_ganadora(
		fichas("bam2 bam2 bam2 dB dB dB dB cir2 cir2 cir2 car6 car6 car6 car6"),
		mano("Año 2026")), "año 2026 con tres palos distintos")
	comprobar(not Validador.es_mano_ganadora(
		fichas("bam2 bam2 bam2 dB dB dB dB cir2 cir2 cir2 cir6 cir6 cir6 cir6"),
		mano("Año 2026")), "año 2026 repitiendo palo NO vale")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor flor dV dV dV dV dR dR dR dR dB dB dB"),
		mano("Tres dragones")), "tres dragones")
	comprobar(Validador.es_mano_ganadora(
		fichas("bam3 bam3 bam4 bam4 bam5 bam5 bam6 bam6 bam7 bam7 bam8 bam8 bam9 bam9"),
		mano("Parejas en escalera")), "parejas del 3 al 9")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8"),
		mano("Pares del 2 al 8")), "13 fichas nunca son mano ganadora")
	var ganadora := Validador.buscar_mano_ganadora(
		fichas("vN vN vN vN vE vE vE vO vO vO vS vS vS vS"), Tarjeta.manos())
	comprobar(ganadora.get("nombre", "") == "Los cuatro vientos", "buscar_mano_ganadora encuentra los vientos")


func probar_comodines() -> void:
	print("Comodines:")
	comprobar(Validador.es_mano_ganadora(
		fichas("flor flor car2 car2 comodin car4 comodin comodin car6 car6 car6 car8 car8 car8"),
		mano("Pares del 2 al 8")), "los comodines completan pungs")
	comprobar(not Validador.es_mano_ganadora(
		fichas("flor comodin car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8 car8"),
		mano("Pares del 2 al 8")), "un comodín NO puede completar la pareja de flores")
	comprobar(not Validador.es_mano_ganadora(
		fichas("bam3 comodin bam4 bam4 bam5 bam5 bam6 bam6 bam7 bam7 bam8 bam8 bam9 bam9"),
		mano("Parejas en escalera")), "un comodín NO vale en una mano de parejas")
	comprobar(Validador.es_mano_ganadora(
		fichas("vN vN comodin comodin vE vE vE vO vO comodin vS vS vS vS"),
		mano("Los cuatro vientos")), "vientos con 3 comodines")


func probar_consejos() -> void:
	print("Consejos:")
	var casi := fichas("flor flor car2 car2 car2 car4 car4 car4 car6 car6 car6 car8 car8 vN")
	var cercanas := Validador.manos_mas_cercanas(casi, Tarjeta.manos(), 3)
	comprobar(cercanas.size() == 3, "devuelve las 3 manos más cercanas")
	comprobar(cercanas[0]["mano"]["nombre"] == "Pares del 2 al 8", "la más cercana es 'Pares del 2 al 8'")
	comprobar(cercanas[0]["faltan"] == 1, "le falta 1 ficha")
	var utiles := Validador.ids_utiles(casi, cercanas[0])
	comprobar(utiles.size() == 13, "13 fichas útiles")
	comprobar(not utiles.has(casi[13].id), "el viento Norte es la ficha que sobra")
