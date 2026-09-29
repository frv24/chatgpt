class_name Ficha
extends RefCounted
## Una ficha del Mahjong americano.
##
## El juego completo tiene 152 fichas:
##   - 3 palos numéricos (bambúes, caracteres y círculos), del 1 al 9, 4 de cada una = 108
##   - 4 vientos (Norte, Este, Oeste, Sur), 4 de cada uno = 16
##   - 3 dragones (Rojo, Verde y Blanco), 4 de cada uno = 12
##   - 8 flores
##   - 8 comodines

enum Tipo { NUMERO, VIENTO, DRAGON, FLOR, COMODIN }

# Palos numéricos. En el código usamos las claves clásicas ("bam", "car", "cir"),
# pero en pantalla se muestran los nombres del diseño de las fichas:
#   bam (bambú)    -> Nopal
#   car (carácter) -> Picado
#   cir (círculo)  -> Sol
# Cada palo tiene un dragón "hermano": Nopal -> Maguey (verde),
# Picado -> Chile (rojo), Sol -> Blanco.
const PALOS := ["bam", "car", "cir"]
const DRAGON_DEL_PALO := {"bam": "V", "car": "R", "cir": "B"}

const NOMBRE_PALO := {"bam": "Nopal", "car": "Picado", "cir": "Sol"}
const NOMBRE_VIENTO := {"N": "Norte", "E": "Este", "O": "Oeste", "S": "Sur"}
const NOMBRE_DRAGON := {"R": "Chile", "V": "Maguey", "B": "Blanco"}

var tipo: Tipo
## Para NUMERO: "bam", "car" o "cir". Para VIENTO: "N", "E", "O" o "S".
## Para DRAGON: "R", "V" o "B". Vacío para FLOR y COMODIN.
var palo: String = ""
## Solo se usa en fichas NUMERO (1 a 9).
var valor: int = 0
## Número único de esta ficha física (0 a 151). Sirve para distinguir
## dos fichas iguales, por ejemplo dos "bambú 5".
var id: int = 0


func _init(p_tipo: Tipo, p_palo: String = "", p_valor: int = 0, p_id: int = 0) -> void:
	tipo = p_tipo
	palo = p_palo
	valor = p_valor
	id = p_id


## Crea una ficha a partir de su clave (lo contrario de clave()).
## Ejemplo: Ficha.desde_clave("bam5") es un Nopal 5.
static func desde_clave(clave: String, p_id: int = 0) -> Ficha:
	if clave == "flor":
		return Ficha.new(Tipo.FLOR, "", 0, p_id)
	if clave == "comodin":
		return Ficha.new(Tipo.COMODIN, "", 0, p_id)
	if clave.begins_with("v"):
		return Ficha.new(Tipo.VIENTO, clave.substr(1), 0, p_id)
	if clave.begins_with("d"):
		return Ficha.new(Tipo.DRAGON, clave.substr(1), 0, p_id)
	return Ficha.new(Tipo.NUMERO, clave.substr(0, 3), int(clave.substr(3)), p_id)


## Clave de texto que identifica la "clase" de ficha, sin importar cuál copia es.
## Ejemplos: "bam5", "car3", "vN", "dR", "flor", "comodin".
## Las fichas iguales tienen la misma clave.
func clave() -> String:
	match tipo:
		Tipo.NUMERO:
			return palo + str(valor)
		Tipo.VIENTO:
			return "v" + palo
		Tipo.DRAGON:
			return "d" + palo
		Tipo.FLOR:
			return "flor"
		_:
			return "comodin"


func es_comodin() -> bool:
	return tipo == Tipo.COMODIN


## Nombre completo en español, para mostrar al jugador.
func nombre() -> String:
	match tipo:
		Tipo.NUMERO:
			return "%s %d" % [NOMBRE_PALO[palo], valor]
		Tipo.VIENTO:
			return "Viento " + NOMBRE_VIENTO[palo]
		Tipo.DRAGON:
			return NOMBRE_DRAGON[palo]
		Tipo.FLOR:
			return "Cempasúchil"
		_:
			return "Comodín"


## Número que se usa para ordenar la mano: primero bambúes, luego caracteres,
## círculos, vientos, dragones, flores y al final los comodines.
func orden() -> int:
	match tipo:
		Tipo.NUMERO:
			return PALOS.find(palo) * 10 + valor
		Tipo.VIENTO:
			return 40 + "NEOS".find(palo)
		Tipo.DRAGON:
			return 50 + "RVB".find(palo)
		Tipo.FLOR:
			return 60
		_:
			return 70


func _to_string() -> String:
	return clave()
