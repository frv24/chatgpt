extends SceneTree
## Crea las capturas para la tienda (Google Play): juega sola unas partidas, toma fotos
## y las pone en un marco rosa con una frase. Se ejecuta con pantalla de 1600 x 900:
##   godot --resolution 1600x900 --script res://herramientas/capturas_tienda.gd
## Resultado: tienda/capturas/1_... a 6_... (1920 x 1080).

const ROSA := Color("c2185b")
const CREMA := Color("fbf3e4")
const ANCHO := 1920
const ALTO := 1080
const CARPETA := "res://tienda/capturas/"

const FRASES := [
	["1_menu", "Mahjong americano en español", "Para todas las edades, con tus fichas de tema mexicano"],
	["2_tutorial", "Aprende a jugar paso a paso", "Un tutorial que te guía hasta tu primer ¡Mahjong!"],
	["3_charleston", "Entiende el Charleston", "Las flechas te enseñan hacia dónde van las fichas"],
	["4_tarjeta", "La Tarjeta 2026, fácil de entender", "Primero las manos que tienes más cerca, con tus fichas marcadas"],
	["5_partida", "Consejos en cada jugada", "Fichas grandes: tócalas para verlas todavía más grandes"],
	["6_mahjong", "¡Celebra tu Mahjong!", "Cuatro niveles: de Fácil a Experto, como en la mesa real"],
]

var main
var _fotos := {}


func _initialize() -> void:
	var c := ConfigFile.new()
	c.set_value("partida", "nivel", "facil")
	c.set_value("partida", "tutorial_hecho", true)
	c.set_value("lecciones", "vistas", Lecciones.ORDEN)
	c.save("user://progreso.cfg")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	_jugar()


func _foto(nombre: String) -> void:
	print("Foto: ", nombre)
	await esperar(0.6)
	_fotos[nombre] = root.get_viewport().get_texture().get_image()


func esperar(seg: float) -> void:
	await create_timer(seg).timeout


func _tocar(clave: String) -> void:
	await process_frame
	for fv in main._fila_mano.get_children():
		if fv.is_queued_for_deletion():
			continue
		if fv.ficha.clave() == clave and not fv.ficha.id in main.seleccion:
			main._al_tocar_ficha(fv)
			return


func _jugar() -> void:
	await esperar(0.5)
	main._menu.abrir(true)
	await _foto("1_menu")
	main._menu.visible = false

	# Tutorial: el paso en que brillan las fichas para el Charleston.
	main.empezar_tutorial()
	for i in 4:
		main.tutorial_continuar()
	await _foto("2_tutorial")

	# Partida en Fácil: el Charleston con las flechas y 2 fichas elegidas.
	main.pausa_forzada = 0.05
	main.elegir_nivel("facil")
	main._capa_leccion.visible = false
	var sobran := Asesor.fichas_que_sobran(main.mano, main.manos_tarjeta, 2)
	for f in sobran:
		main.seleccion.append(f.id)
	main._refrescar()
	await _foto("3_charleston")

	main.seleccion.clear()
	main._abrir_tarjeta()
	await _foto("4_tarjeta")
	main._ventana_tarjeta.visible = false

	# Terminar el Charleston y jugar hasta que te toque descartar.
	while main.fase == main.Fase.CHARLESTON:
		if main.charleston.etapa == Charleston.Etapa.PREGUNTA_SEGUNDO:
			main.decidir_segundo_charleston(false)
		else:
			main.seleccion.clear()
			if main.charleston.etapa != Charleston.Etapa.CORTESIA:
				for f in Asesor.fichas_que_sobran(main.mano, main.manos_tarjeta, 3):
					main.seleccion.append(f.id)
			main.pasar_fichas()
		await process_frame
	var turnos := 0
	while turnos < 12 and main.fase != main.Fase.FIN:
		await esperar(0.1)
		main._capa_leccion.visible = false
		if main.fase == main.Fase.ROBAR:
			main.robar()
			turnos += 1
			if turnos >= 6 and main.fase == main.Fase.DESCARTAR:
				break
		elif main.fase == main.Fase.DESCARTAR:
			main.seleccion.clear()
			main.seleccion.append(Asesor.fichas_que_sobran(main.mano, main.manos_tarjeta, 1)[0].id)
			main.descartar()
		elif main.fase == main.Fase.DECIDIR_CANTO:
			main.decidir_canto("pasar")
	main.pausa_forzada = 100.0
	main.pausa_rivales = 100.0
	main._timer_rivales.stop()
	await esperar(0.3)
	# Toca una ficha: se ve en grande.
	var fichas: Array = main._fila_mano.get_children()
	main._al_tocar_ficha(fichas[fichas.size() - 1])
	await esperar(0.25)
	_fotos["5_partida"] = root.get_viewport().get_texture().get_image()

	# Tutorial completo hasta el Mahjong.
	main.pausa_forzada = 0.05
	main.empezar_tutorial()
	for i in 4:
		main.tutorial_continuar()
	for clave in ["vS", "cir3", "dV"]:
		await _tocar(clave)
	main.pasar_fichas()
	main.tutorial_continuar()
	main.tutorial_continuar()
	while main.fase != main.Fase.DECIDIR_CANTO:
		await esperar(0.1)
	main.decidir_canto("exponer", 3)
	await _tocar("car1")
	main.descartar()
	while main.fase != main.Fase.ROBAR:
		await esperar(0.1)
	main._lupa.visible = false
	main.robar()
	main._quitar_resalte()
	await esperar(1.8)
	_fotos["6_mahjong"] = root.get_viewport().get_texture().get_image()

	await _enmarcar()
	quit()


## Pone cada foto en un marco rosa con papel picado y una frase.
func _enmarcar() -> void:
	main.visible = false
	main.queue_free()
	var carpeta := ProjectSettings.globalize_path(CARPETA)
	for archivo in DirAccess.get_files_at(carpeta):
		if archivo.ends_with(".png"):
			DirAccess.remove_absolute(carpeta.path_join(archivo))
	for frase in FRASES:
		var vista := SubViewport.new()
		vista.size = Vector2i(ANCHO, ALTO)
		vista.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(vista)

		var fondo := ColorRect.new()
		fondo.color = ROSA
		fondo.size = Vector2(ANCHO, ALTO)
		vista.add_child(fondo)
		var picado := PapelPicado.new()
		picado.color_fondo = ROSA
		picado.colores = PapelPicado.COLORES.filter(func(c): return c != ROSA) + [CREMA]
		picado.size = Vector2(ANCHO / 1.2, 58)
		picado.scale = Vector2(1.2, 1.2)
		picado.position = Vector2(0, -8)
		vista.add_child(picado)

		var titulo := _texto(frase[1], 66, CREMA)
		titulo.position.y = 70
		vista.add_child(titulo)
		var subtitulo := _texto(frase[2], 34, Color("f8bbd0"))
		subtitulo.position.y = 160
		vista.add_child(subtitulo)

		var tam := Vector2(1440, 810) * 0.98
		var marco := Panel.new()
		var estilo := StyleBoxFlat.new()
		estilo.bg_color = CREMA
		estilo.set_corner_radius_all(22)
		estilo.shadow_color = Color(0, 0, 0, 0.35)
		estilo.shadow_size = 18
		marco.add_theme_stylebox_override("panel", estilo)
		marco.size = tam + Vector2(20, 20)
		marco.position = Vector2((ANCHO - marco.size.x) / 2, ALTO - marco.size.y - 22)
		vista.add_child(marco)
		var foto := TextureRect.new()
		foto.texture = ImageTexture.create_from_image(_fotos[frase[0]])
		foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foto.stretch_mode = TextureRect.STRETCH_SCALE
		foto.size = tam
		foto.position = marco.position + Vector2(10, 10)
		vista.add_child(foto)

		for i in 3:
			await process_frame
		vista.get_texture().get_image().save_png(carpeta.path_join(frase[0] + ".png"))
		vista.queue_free()
		print("Captura lista: ", frase[0])


func _texto(texto: String, tam: int, color: Color) -> Label:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.size.x = ANCHO
	etiqueta.add_theme_font_size_override("font_size", tam)
	etiqueta.add_theme_color_override("font_color", color)
	return etiqueta
