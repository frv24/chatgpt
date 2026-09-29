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
	"bam": Color("1b7a3a"),  # bambúes en verde
	"car": Color("b3261e"),  # caracteres en rojo
	"cir": Color("1f4fa3"),  # círculos en azul
}
const SIMBOLO_PALO := {"bam": "Bam", "car": "Car", "cir": "Cír"}

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
## Si es false, la ficha se atenúa (consejo: "esta ficha puedes descartarla").
var mostrar_consejo := false:
	set(v):
		mostrar_consejo = v
		_actualizar_estilo()

var _etiqueta_grande := Label.new()
var _etiqueta_pequena := Label.new()


func _init(p_ficha: Ficha = null) -> void:
	ficha = p_ficha
	custom_minimum_size = TAMANO
	mouse_filter = Control.MOUSE_FILTER_STOP

	var caja := VBoxContainer.new()
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caja)

	for etiqueta in [_etiqueta_grande, _etiqueta_pequena]:
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caja.add_child(etiqueta)
	_etiqueta_grande.add_theme_font_size_override("font_size", 30)
	_etiqueta_pequena.add_theme_font_size_override("font_size", 13)


func _ready() -> void:
	_actualizar_texto()
	_actualizar_estilo()
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
			_etiqueta_pequena.text = {"R": "Rojo", "V": "Verde", "B": "Blanco"}[ficha.palo]
			color = {"R": COLOR_PALO["car"], "V": COLOR_PALO["bam"], "B": COLOR_PALO["cir"]}[ficha.palo]
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
	estilo.bg_color = Color("fbf6e9")  # color marfil de ficha
	estilo.set_corner_radius_all(8)
	estilo.set_border_width_all(2)
	estilo.border_color = Color("9e9480")
	if mostrar_consejo and util:
		estilo.border_color = Color("2e9d4f")
		estilo.set_border_width_all(4)
	if seleccionada:
		estilo.border_color = Color("f2a900")
		estilo.set_border_width_all(5)
	add_theme_stylebox_override("panel", estilo)
	# Las fichas que no sirven se ven más apagadas cuando los consejos están activos.
	modulate = Color(1, 1, 1, 0.55) if mostrar_consejo and not util else Color.WHITE


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
