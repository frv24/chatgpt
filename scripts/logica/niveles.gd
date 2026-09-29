class_name Niveles
extends RefCounted
## Los niveles del juego. Cada nivel decide cuánta ayuda recibes y cómo juegan los rivales.
## Para cambiar un nivel, edita sus valores aquí.
##
##   consejos:      borde verde en las fichas que sirven, fichas apagadas y "Faltan N" en la tarjeta.
##   sugerencias:   cuántas veces se puede pulsar «Sugerir» por partida (-1 = sin límite, 0 = nunca).
##   explicaciones: las lecciones salen solas la primera vez que pasa algo.
##   cantos:        cuándo te avisa el juego de que puedes cantar un descarte:
##                    "explicados" = solo si te conviene, explicando cuánto te acerca;
##                    "utiles"     = solo si te conviene, sin explicación;
##                    "todos"      = siempre que la regla lo permita (como en la mesa real).
##   marcador:      se cuentan puntos y pagos entre partidas.
##   rivales:       "tranquilos" (no exponen grupos y a veces descartan sin pensar),
##                  "normales" o "expertos" (además, evitan darte fichas peligrosas).
##   pausa:         segundos que tarda cada rival en jugar.

const ORDEN := ["facil", "normal", "intermedio", "experto"]

const TODOS := {
	"facil": {
		"nombre": "Fácil",
		"descripcion": "Para aprender desde cero. Todas las ayudas y rivales tranquilos.",
		"consejos": true, "sugerencias": -1, "explicaciones": true, "cantos": "explicados",
		"marcador": false, "rivales": "tranquilos", "pausa": 1.6,
	},
	"normal": {
		"nombre": "Normal",
		"descripcion": "Ya conoces las reglas. Todas las ayudas y rivales que juegan de verdad.",
		"consejos": true, "sugerencias": -1, "explicaciones": true, "cantos": "explicados",
		"marcador": false, "rivales": "normales", "pausa": 1.2,
	},
	"intermedio": {
		"nombre": "Intermedio",
		"descripcion": "Menos ayudas: sin bordes verdes y solo 3 sugerencias por partida. Con puntos y marcador.",
		"consejos": false, "sugerencias": 3, "explicaciones": true, "cantos": "utiles",
		"marcador": true, "rivales": "normales", "pausa": 1.0,
	},
	"experto": {
		"nombre": "Experto",
		"descripcion": "Como en la mesa real: sin ayudas, cantas cuando quieras y rivales que se defienden. Con puntos y marcador.",
		"consejos": false, "sugerencias": 0, "explicaciones": false, "cantos": "todos",
		"marcador": true, "rivales": "expertos", "pausa": 0.8,
	},
}


static func obtener(id: String) -> Dictionary:
	return TODOS.get(id, TODOS["facil"])
