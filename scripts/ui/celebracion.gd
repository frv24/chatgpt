class_name Celebracion
extends Control
## Celebración de ¡Mahjong!: confeti con los colores del papel picado y un letrero
## que aparece rebotando. Se quita sola después de unos segundos o al tocarla.

const DURACION := 3.2

var _letrero: Label
var _confeti: Array[CPUParticles2D] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func _ready() -> void:
	# Un emisor de confeti por cada color del papel picado.
	for color in PapelPicado.COLORES:
		var p := CPUParticles2D.new()
		p.emitting = false
		p.one_shot = true
		p.amount = 36
		p.lifetime = 2.6
		p.explosiveness = 0.85
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(640, 10)
		p.direction = Vector2(0, 1)
		p.spread = 35.0
		p.gravity = Vector2(0, 260)
		p.initial_velocity_min = 60.0
		p.initial_velocity_max = 220.0
		p.angular_velocity_min = -360.0
		p.angular_velocity_max = 360.0
		p.scale_amount_min = 6.0
		p.scale_amount_max = 11.0
		p.color = color
		add_child(p)
		_confeti.append(p)

	_letrero = Label.new()
	_letrero.add_theme_font_size_override("font_size", 84)
	_letrero.add_theme_color_override("font_color", Color("fff3c4"))
	_letrero.add_theme_color_override("font_outline_color", Color("c2185b"))
	_letrero.add_theme_constant_override("outline_size", 18)
	_letrero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_letrero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_letrero.set_anchors_preset(Control.PRESET_FULL_RECT)
	_letrero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_letrero)


## Lanza la celebración. `texto` es lo que dice el letrero.
## Con `grande` = false (cuando gana un rival) hay menos confeti.
func celebrar(texto: String, grande: bool = true, con_animacion: bool = true) -> void:
	visible = true
	_letrero.text = texto
	_letrero.pivot_offset = size / 2
	for p in _confeti:
		p.position = Vector2(size.x / 2, -20)
		p.amount = 36 if grande else 10
		if con_animacion:
			p.restart()
			p.emitting = true
	var tween := create_tween()
	if con_animacion:
		_letrero.scale = Vector2(0.2, 0.2)
		_letrero.modulate.a = 1.0
		tween.tween_property(_letrero, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_letrero.scale = Vector2.ONE
	tween.tween_interval(DURACION - 1.0)
	tween.tween_property(_letrero, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): visible = false)
