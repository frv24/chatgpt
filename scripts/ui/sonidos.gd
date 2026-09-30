class_name Sonidos
extends Node
## Los sonidos del juego, generados con código (sin archivos de audio).
## Así no hace falta descargar nada ni preocuparse por licencias.
##
## Uso: sonidos.tocar("descartar")
## Si más adelante tienes sonidos grabados, pon un archivo con el mismo nombre en
## res://assets/sonidos/ (por ejemplo "mahjong.ogg" o "descartar.wav") y se usará ese.

const FRECUENCIA := 22050
const CARPETA := "res://assets/sonidos/"

var activado := true
## Volumen de 0.0 a 1.0.
var volumen := 0.8:
	set(v):
		volumen = clampf(v, 0.0, 1.0)
		for p in _reproductores:
			p.volume_db = linear_to_db(maxf(volumen, 0.001))

var _sonidos := {}
var _reproductores: Array[AudioStreamPlayer] = []
var _siguiente := 0


func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_reproductores.append(p)
	volumen = volumen
	_sonidos = {
		"boton": _crear(0.05, _boton),
		"seleccionar": _crear(0.06, _seleccionar),
		"descartar": _crear(0.16, _ficha_mesa),
		"robar": _crear(0.22, _robar),
		"pasar": _crear(0.32, _pasar),
		"cantar": _crear(0.55, _cantar),
		"turno": _crear(0.35, _turno),
		"aviso": _crear(0.2, _aviso),
		"mahjong": _crear(1.6, _mahjong),
	}
	# Sonidos grabados que sustituyen a los generados, si existen.
	for nombre in _sonidos:
		for extension in ["ogg", "wav", "mp3"]:
			var ruta := "%s%s.%s" % [CARPETA, nombre, extension]
			if ResourceLoader.exists(ruta):
				_sonidos[nombre] = load(ruta)
				break


func tocar(nombre: String, volumen_relativo: float = 1.0) -> void:
	if not activado or not _sonidos.has(nombre) or volumen <= 0.0:
		return
	var p := _reproductores[_siguiente]
	_siguiente = (_siguiente + 1) % _reproductores.size()
	p.stream = _sonidos[nombre]
	p.volume_db = linear_to_db(maxf(volumen * volumen_relativo, 0.001))
	p.play()


# =============================================================================
#  SÍNTESIS: cada función devuelve la muestra (-1 a 1) en el instante t (segundos)
# =============================================================================

func _crear(duracion: float, funcion: Callable) -> AudioStreamWAV:
	var n := int(duracion * FRECUENCIA)
	var datos := PackedByteArray()
	datos.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var suave := 0.0
	for i in n:
		var t := float(i) / FRECUENCIA
		var ruido := rng.randf_range(-1.0, 1.0)
		suave = suave * 0.8 + ruido * 0.2  # ruido más grave (filtro sencillo)
		var v: float = funcion.call(t, ruido, suave)
		# Pequeño fundido al final para que no haga "clic".
		var fin := clampf((duracion - t) / 0.01, 0.0, 1.0)
		datos.encode_s16(i * 2, int(clampf(v * fin, -1.0, 1.0) * 32000))
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = FRECUENCIA
	sonido.stereo = false
	sonido.data = datos
	return sonido


## Una nota de marimba: tono base más un armónico que se apaga antes.
func _marimba(t: float, f: float, largo: float = 0.25) -> float:
	if t < 0.0:
		return 0.0
	return sin(TAU * f * t) * exp(-t / largo) + 0.35 * sin(TAU * f * 4.0 * t) * exp(-t / (largo / 4.0))


func _boton(t: float, _r: float, _s: float) -> float:
	return 0.35 * sin(TAU * 1500.0 * t) * exp(-t / 0.012)


func _seleccionar(t: float, _r: float, s: float) -> float:
	return 0.4 * sin(TAU * 2100.0 * t) * exp(-t / 0.015) + 0.2 * s * exp(-t / 0.006)


## El "clac" de una ficha al tocar la mesa.
func _ficha_mesa(t: float, r: float, s: float) -> float:
	var golpe := 0.6 * s * exp(-t / 0.012) + 0.25 * r * exp(-t / 0.004)
	var madera := 0.45 * sin(TAU * 720.0 * t) * exp(-t / 0.03) + 0.25 * sin(TAU * 1650.0 * t) * exp(-t / 0.018)
	return golpe + madera


## Deslizar una ficha del muro y dejarla en el atril.
func _robar(t: float, r: float, s: float) -> float:
	var deslizar := 0.25 * s * sin(PI * clampf(t / 0.14, 0.0, 1.0))
	return deslizar + 0.8 * _ficha_mesa(t - 0.14, r, s) * (1.0 if t > 0.14 else 0.0)


## Un "fsss" suave al pasar fichas.
func _pasar(t: float, _r: float, s: float) -> float:
	return 0.55 * s * pow(sin(PI * t / 0.32), 2.0)


## Dos notas alegres al cantar.
func _cantar(t: float, _r: float, _s: float) -> float:
	return 0.35 * (_marimba(t, 784.0) + _marimba(t - 0.12, 1175.0, 0.35))


## Aviso suave de que te toca.
func _turno(t: float, _r: float, _s: float) -> float:
	return 0.3 * (_marimba(t, 988.0, 0.2) + 0.6 * _marimba(t - 0.09, 1319.0, 0.2))


## Nota grave y corta para "eso no".
func _aviso(t: float, _r: float, _s: float) -> float:
	return 0.35 * sin(TAU * 247.0 * t) * exp(-t / 0.08)


## Fanfarria de ¡Mahjong!: arpegio de marimba y acorde final.
func _mahjong(t: float, _r: float, _s: float) -> float:
	var notas := [523.25, 659.25, 783.99, 1046.5, 783.99, 1046.5]
	var v := 0.0
	for i in notas.size():
		v += _marimba(t - i * 0.11, notas[i], 0.3)
	var acorde := t - 0.7
	if acorde > 0.0:
		for f in [523.25, 659.25, 783.99, 1046.5]:
			v += 0.7 * _marimba(acorde, f, 0.6)
	return 0.18 * v
