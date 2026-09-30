class_name Entrenador
extends RefCounted
## El «entrenador»: consejos que aparecen solos durante la partida, sin pedirlos,
## en los niveles para aprender (Fácil, Normal e Intermedio; ver niveles.gd).
##
## Cada función mira la situación y devuelve un consejo corto, o "" si no hay nada
## que decir. Los textos se pueden cambiar aquí sin tocar nada más.


## Nombres legibles de una lista de claves. Ejemplo: ["bam8", "bam8", "flor"] ->
## "dos Nopal 8 y Cempasúchil".
static func nombrar(claves: Array) -> String:
	var cuenta := {}
	var orden: Array[String] = []
	for c in claves:
		if not cuenta.has(c):
			orden.append(c)
		cuenta[c] = cuenta.get(c, 0) + 1
	var partes: Array[String] = []
	var numeros := {2: "dos", 3: "tres", 4: "cuatro", 5: "cinco"}
	for c in orden:
		var nombre := Ficha.desde_clave(c).nombre()
		partes.append(nombre if cuenta[c] == 1 else "%s %s" % [numeros.get(cuenta[c], str(cuenta[c])), nombre])
	if partes.size() == 1:
		return partes[0]
	return ", ".join(partes.slice(0, partes.size() - 1)) + " y " + partes[-1]


## Durante el Charleston: qué pasar.
static func charleston(ch: Charleston, objetivo: Dictionary, con_bordes: bool) -> String:
	if ch.etapa == Charleston.Etapa.PREGUNTA_SEGUNDO:
		return "Si todavía te faltan muchas fichas, el segundo Charleston te da otra oportunidad de mejorar tu mano."
	if ch.etapa == Charleston.Etapa.CORTESIA:
		return "En la cortesía puedes pasar 0 fichas si ya estás contento con tu mano."
	if ch.es_pase_ciego() and not ch.bandeja.is_empty():
		return "¿Te sirven tus fichas? Si no quieres romper tu mano, pasa las de boca abajo sin mirarlas."
	if con_bordes:
		return "Pasa fichas que no sirvan para «%s»: las que se ven apagadas. Nunca pases comodines." % objetivo["nombre"]
	return "Pasa fichas que no sirvan para «%s». Nunca pases comodines." % objetivo["nombre"]


## Después de robar: ¿la ficha te sirve?
static func tras_robar(ficha: Ficha, mano: Array[Ficha], objetivo: Dictionary, expuestas: Array) -> String:
	if ficha.es_comodin():
		return "¡Un comodín! Guárdalo: sirve en cualquier grupo de 3 o más."
	var analisis := Validador.analizar(mano, objetivo, expuestas)
	if analisis["faltan"] == Validador.IMPOSIBLE:
		return ""
	if ficha.id in Validador.ids_utiles(mano, analisis):
		return "¡El %s te sirve para «%s»! Quédatelo." % [ficha.nombre(), objetivo["nombre"]]
	return "El %s no te sirve para «%s»: puedes descartarlo." % [ficha.nombre(), objetivo["nombre"]]


## Cuando te faltan pocas fichas: cuáles son.
static func cerca_de_ganar(mano: Array[Ficha], objetivo: Dictionary, expuestas: Array) -> String:
	var faltan := Validador.fichas_que_faltan(mano, objetivo, expuestas)
	if faltan.is_empty() or faltan.size() > 2:
		return ""
	if faltan.size() == 1:
		return "¡Estás a UNA ficha de ganar! Te falta %s: si alguien la tira, ¡cántala!" % nombrar(faltan)
	return "¡Ya casi! Te faltan %s para «%s»." % [nombrar(faltan), objetivo["nombre"]]


## Si otra mano de la tarjeta está bastante más cerca que tu objetivo.
static func mejor_objetivo(mano: Array[Ficha], objetivo: Dictionary, manos_tarjeta: Array[Dictionary], expuestas: Array) -> String:
	var mia: int = Validador.analizar(mano, objetivo, expuestas)["faltan"]
	var mejor: Dictionary = Validador.manos_mas_cercanas(mano, manos_tarjeta, 1, expuestas)[0]
	if mejor["mano"]["nombre"] == objetivo["nombre"] or mia - mejor["faltan"] < 2:
		return ""
	if mia == Validador.IMPOSIBLE:
		return "«%s» ya no es posible con tus grupos expuestos. Prueba con «%s» (te faltan %d)." % [
			objetivo["nombre"], mejor["mano"]["nombre"], mejor["faltan"]]
	return "«%s» está más cerca que tu objetivo: te faltan %d en vez de %d. Tócala en la tarjeta para cambiar." % [
		mejor["mano"]["nombre"], mejor["faltan"], mia]


## Al elegir qué descartar: avisos antes de cometer un error.
static func aviso_descarte(ficha: Ficha, p: Partida, objetivo: Dictionary) -> String:
	if ficha.es_comodin():
		return "¡Es un comodín! Casi nunca conviene tirarlo: sirve en cualquier grupo de 3 o más."
	for j in range(1, 4):
		for g in p.expuestas[j]:
			if g["clave"] == ficha.clave():
				return "Ojo: %s tiene expuesto un grupo de %s. Si lo tiras, podría cantarlo y acercarse a ganar." % [
					p.nombre(j), ficha.nombre()]
	var analisis := Validador.analizar(p.manos[0], objetivo, p.expuestas[0])
	if analisis["faltan"] != Validador.IMPOSIBLE and ficha.id in Validador.ids_utiles(p.manos[0], analisis):
		return "Ojo: el %s te sirve para «%s». ¿Seguro que quieres tirarlo?" % [ficha.nombre(), objetivo["nombre"]]
	return ""


## Cuando un rival expone un grupo: qué nos dice.
static func exposicion_rival(p: Partida, jugador: int, ficha: Ficha) -> String:
	return "%s expuso un grupo de %s. Ya sabes que juega con esa ficha: evita tirársela." % [
		p.nombre(jugador), ficha.nombre()]
