class_name FichaVisual
extends PanelContainer
## Dibuja una ficha en pantalla (sin imágenes: un rectángulo con color y texto).
## Más adelante puedes cambiarlo por dibujos de verdad sin tocar la lógica.
##
## Se puede tocar (para seleccionarla) y arrastrar (para reordenar la mano).

## Se emite al tocar la ficha.
signal tocada(ficha_visual: FichaVisual)
## Se emite cuando sueltan otra ficha encima de esta (para reordenar).
signal soltada_encima(origen: FichaVisual, destino: FichaVisual)

const TAMANO := Vector2(64, 88)

# Color del texto según el tipo de ficha.
const COLOR_PALO := {
	"bam": Color("1f6b3f"),  # Nopal en verde
	"car": Color("c2185b"),  # Picado en rosa mexicano
	"cir": Color("b5441f"),  # Sol en naranja
}
const SIMBOLO_PALO := {"bam": "Nopal", "car": "Picado", "cir": "Sol"}

var ficha: Ficha
var seleccionada := false:
	set(v):
		seleccionada = v
		_actualizar_estilo()
## Si es true, se marca con borde verde (consejo: "esta ficha te sirve").
var util := false:
	set(v):
		util = v
		_actualizar_estilo()
## Si es true, se pinta con fondo amarillo: es una ficha que acabas de recibir.
var nueva := false:
	set(v):
		nueva = v
		_actualizar_estilo()
## Si es true, la ficha brilla con un pulso amarillo (el tutorial señala qué tocar).
var resaltada := false:
	set(v):
		resaltada = v
		_actualizar_pulso()
var _brillo := 0.0
var _pulso: Tween = null
## Si es false, la ficha se atenúa (consejo: "esta ficha puedes descartarla").
var mostrar_consejo := false:
	set(v):
		mostrar_consejo = v
		_actualizar_estilo()

## Carpeta de los diseños de las fichas. Si existe un archivo con el nombre de la
## clave de la ficha (por ejemplo "bam5.png" o "comodin.png"), se usa esa imagen.
## Si no existe, la ficha se dibuja con texto. Ver assets/fichas/LEEME.md.
const CARPETA_DISENOS := "res://assets/fichas/"

var _caja_textos := VBoxContainer.new()
var _etiqueta_grande := Label.new()
var _etiqueta_pequena := Label.new()
var _imagen: TextureRect = null


## Devuelve la imagen del diseño de una ficha, o null si todavía no hay diseño.
static func diseno_de(clave: String) -> Texture2D:
	for extension in ["png", "svg", "webp"]:
		var ruta := "%s%s.%s" % [CARPETA_DISENOS, clave, extension]
		if ResourceLoader.exists(ruta):
			return load(ruta)
	return null


func _init(p_ficha: Ficha = null) -> void:
	ficha = p_ficha
	custom_minimum_size = TAMANO
	mouse_filter = Control.MOUSE_FILTER_STOP

	_caja_textos.alignment = BoxContainer.ALIGNMENT_CENTER
	_caja_textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caja_textos)

	for etiqueta in [_etiqueta_grande, _etiqueta_pequena]:
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_caja_textos.add_child(etiqueta)
	_etiqueta_grande.add_theme_font_size_override("font_size", 30)
	_etiqueta_pequena.add_theme_font_size_override("font_size", 13)


func _ready() -> void:
	var textura := diseno_de(ficha.clave())
	if textura:
		# Hay diseño: se muestra la imagen en lugar del texto.
		_imagen = TextureRect.new()
		_imagen.texture = textura
		_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_imagen)
		_caja_textos.visible = false
	else:
		_actualizar_texto()
	_actualizar_pulso()
	tooltip_text = ficha.nombre()


func _actualizar_texto() -> void:
	var color := Color("222222")
	match ficha.tipo:
		Ficha.Tipo.NUMERO:
			_etiqueta_grande.text = str(ficha.valor)
			_etiqueta_pequena.text = SIMBOLO_PALO[ficha.palo]
			color = COLOR_PALO[ficha.palo]
		Ficha.Tipo.VIENTO:
			_etiqueta_grande.text = ficha.palo
			_etiqueta_pequena.text = "Viento"
		Ficha.Tipo.DRAGON:
			_etiqueta_grande.text = "D"
			_etiqueta_pequena.text = Ficha.NOMBRE_DRAGON[ficha.palo]
			color = {"R": Color("b3261e"), "V": COLOR_PALO["bam"], "B": Color("1f4fa3")}[ficha.palo]
		Ficha.Tipo.FLOR:
			_etiqueta_grande.text = "✿"
			_etiqueta_pequena.text = "Flor"
			color = Color("c2185b")
		Ficha.Tipo.COMODIN:
			_etiqueta_grande.text = "J"
			_etiqueta_pequena.text = "Comodín"
			color = Color("6a1b9a")
	for etiqueta in [_etiqueta_grande, _etiqueta_pequena]:
		etiqueta.add_theme_color_override("font_color", color)


func _actualizar_estilo() -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("fff1a8") if nueva else Color("fbf6e9")  # amarillo o marfil
	estilo.set_corner_radius_all(8)
	# Margen interior: así el borde de consejo/selección se ve alrededor del diseño.
	estilo.set_content_margin_all(4)
	estilo.set_border_width_all(2)
	estilo.border_color = Color("9e9480")
	if mostrar_consejo and util:
		estilo.border_color = Color("2e9d4f")
		estilo.set_border_width_all(4)
	if seleccionada:
		estilo.border_color = Color("f2a900")
		estilo.set_border_width_all(5)
	if resaltada and not seleccionada:
		estilo.border_color = Color("fff176").lerp(Color("ff9800"), _brillo)
		estilo.set_border_width_all(6)
	add_theme_stylebox_override("panel", estilo)
	if _imagen:
		# Con diseño, las fichas nuevas se tiñen de amarillo.
		_imagen.self_modulate = Color(1, 0.93, 0.55) if nueva else Color.WHITE
	# Las fichas que no sirven se ven más apagadas cuando los consejos están activos
	# (salvo las nuevas y las seleccionadas, que deben verse bien).
	var apagada := mostrar_consejo and not util and not nueva and not seleccionada and not resaltada
	modulate = Color(1, 1, 1, 0.55) if apagada else Color.WHITE


func _gui_input(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and not evento.pressed:
		tocada.emit(self)
		accept_event()


# --- Arrastrar y soltar (lo gestiona Godot automáticamente) --------------------

func _get_drag_data(_posicion: Vector2) -> Variant:
	# La "vista previa" es una copia de la ficha que sigue al dedo.
	var vista := FichaVisual.new(ficha)
	vista.modulate.a = 0.8
	var contenedor := Control.new()
	contenedor.add_child(vista)
	vista.position = -TAMANO / 2
	set_drag_preview(contenedor)
	return self


func _can_drop_data(_posicion: Vector2, datos: Variant) -> bool:
	return datos is FichaVisual and datos != self


func _drop_data(_posicion: Vector2, datos: Variant) -> void:
	soltada_encima.emit(datos, self)


func _actualizar_pulso() -> void:
	if _pulso:
		_pulso.kill()
		_pulso = null
	if resaltada and is_inside_tree():
		_pulso = create_tween().set_loops()
		_pulso.tween_method(_poner_brillo, 0.0, 1.0, 0.45)
		_pulso.tween_method(_poner_brillo, 1.0, 0.0, 0.45)
	_actualizar_estilo()


func _poner_brillo(valor: float) -> void:
	_brillo = valor
	_actualizar_estilo()


## Pequeño salto al aparecer (fichas que acabas de recibir o robar, descartes nuevos).
## `escala_final` es la escala normal de la ficha (menor en los descartes).
## Con `centrada` = false crece desde la esquina (para fichas ya encogidas en un hueco).
func animar_entrada(escala_final: float = 1.0, centrada: bool = true) -> void:
	if centrada:
		pivot_offset = TAMANO / 2
	scale = Vector2.ONE * escala_final * 0.4
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * escala_final, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
