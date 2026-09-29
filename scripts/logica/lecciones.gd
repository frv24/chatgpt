class_name Lecciones
extends RefCounted
## Las explicaciones del "¿por qué?" de cada regla.
##
## Cada lección tiene:
##   "titulo": el título.
##   "texto":  qué es y por qué se hace así.
##   "mesa":   cómo se hace en una mesa real, para que luego puedas jugar en físico.
##
## Se muestran solas la primera vez que pasa algo en la partida
## y también se pueden leer todas desde el botón «Reglas».

## Orden en el que aparecen en el botón «Reglas».
const ORDEN := [
	"preparar_mesa", "asientos",
	"charleston", "charleston_direcciones", "comodines_charleston",
	"ultimo_pase", "segundo_charleston", "cortesia",
	"turnos", "descartes_rivales",
	"cantar", "exponer", "manos_ocultas", "cambiar_comodin",
	"mahjong", "muro_vacio",
]

const TODAS := {
	"preparar_mesa": {
		"titulo": "Antes de empezar: preparar la mesa",
		"texto": "El Mahjong americano se juega entre 4 personas con 152 fichas. Se ponen todas boca abajo y se mezclan. Después cada jugador construye delante de sí un muro de 19 columnas de 2 fichas (38 fichas cada uno).",
		"mesa": "El Este tira los dados para saber por dónde se abre el muro. Luego cada jugador coge 4 fichas, tres veces seguidas (12), y después 1 más (13). El Este coge una ficha extra: empieza con 14. En esta app el reparto se hace solo.",
	},
	"asientos": {
		"titulo": "Los asientos y los vientos",
		"texto": "A cada jugador le toca un viento. El Este es la \"banca\": reparte y empieza. A su derecha se sienta el Sur, después el Oeste y después el Norte. El juego siempre avanza hacia la DERECHA.",
		"mesa": "Al terminar una partida, el puesto de Este pasa al jugador de su derecha. En esta app también rota: mira arriba qué viento te toca en cada partida.",
	},
	"charleston": {
		"titulo": "¿Por qué empezamos con el Charleston?",
		"texto": "Las fichas se reparten al azar, así que casi nadie empieza con una buena mano. El Charleston es un intercambio de fichas ANTES de jugar: cada uno se deshace de lo que no le sirve y recibe fichas que quizá sí le sirvan. Solo existe en el Mahjong americano.",
		"mesa": "Antes de pasar, mira la tarjeta y piensa a qué mano vas a jugar: pasa lo que no encaje. Todos pasan a la vez: pon tus 3 fichas boca abajo junto a tu atril, del lado de quien las recibe, y no cojas las que te pasan hasta haber dejado las tuyas.",
	},
	"charleston_direcciones": {
		"titulo": "¿Hacia dónde se pasa y cuántas veces?",
		"texto": "PRIMER Charleston (obligatorio): 3 pases de 3 fichas: a la DERECHA → ENFRENTE → a la IZQUIERDA.\nSEGUNDO Charleston (opcional): 3 pases más, en orden inverso: a la IZQUIERDA → ENFRENTE → a la DERECHA.\nAl final, un pase de CORTESÍA opcional con el de enfrente.\nComo mucho son 7 pases.",
		"mesa": "Truco para recordarlo: el primero va \"Derecha, Enfrente, Izquierda\" y el segundo es su espejo: \"Izquierda, Enfrente, Derecha\". En cada pase se dan siempre 3 fichas (menos en la cortesía).",
	},
	"comodines_charleston": {
		"titulo": "Los comodines no se pasan",
		"texto": "En el Charleston nunca puedes pasar un comodín. Son las fichas más valiosas: sustituyen a cualquier ficha en un grupo de 3 o más (pung, kong, quint).",
		"mesa": "Si alguien te pasa un comodín por error, avisa: hay que devolverlo y cambiarlo por otra ficha.",
	},
	"ultimo_pase": {
		"titulo": "El último pase y el \"pase a ciegas\"",
		"texto": "El tercer pase del primer Charleston (a la izquierda) permite el \"pase a ciegas\". Si no quieres romper tu mano, puedes pasar 1, 2 o 3 de las fichas que te acaban de dar SIN MIRARLAS, y completar hasta 3 con fichas tuyas. Lo mismo vale en el último pase del segundo Charleston (a la derecha).",
		"mesa": "Recoge las fichas que te pasan sin darles la vuelta y pásalas directamente. En esta app el pase a ciegas todavía no está disponible.",
	},
	"segundo_charleston": {
		"titulo": "¿Hacemos el segundo Charleston?",
		"texto": "El segundo Charleston es opcional, y basta con que UN jugador no quiera para que no se haga. Conviene hacerlo si tu mano aún está lejos de todas las de la tarjeta. Si ya estás cerca, puedes pararlo para no arriesgar.",
		"mesa": "Al acabar el primer Charleston se pregunta en voz alta: \"¿Seguimos?\". Si alguien dice que no, se pasa directamente a la cortesía.",
	},
	"cortesia": {
		"titulo": "El pase de cortesía",
		"texto": "Es el último intercambio y solo se hace con el jugador de ENFRENTE, de 0 a 3 fichas. Es opcional.",
		"mesa": "Os ponéis de acuerdo en cuántas pasar. Si tú quieres pasar 3 y tu compañero solo 1, se pasa 1: manda el número más pequeño. En esta app, el rival de enfrente te pasa tantas como le pases tú.",
	},
	"turnos": {
		"titulo": "Empieza el juego: los turnos",
		"texto": "El Este empieza: como tiene 14 fichas, descarta una sin robar. Después el turno pasa a la DERECHA. En tu turno: 1) robas una ficha del muro; 2) si tus 14 fichas forman una mano de la tarjeta, ¡Mahjong!; 3) si no, descartas una y vuelves a 13.",
		"mesa": "Al descartar, di en voz alta el nombre de la ficha (\"¡5 bambú!\") y déjala boca arriba en el centro de la mesa. Así todos saben qué se ha tirado.",
	},
	"descartes_rivales": {
		"titulo": "Fíjate en los descartes de los demás",
		"texto": "Los descartes dan pistas. Si alguien tira muchos bambúes, seguramente no juega a bambúes. Y si un rival no tira nunca dragones, quizá los esté juntando: ten cuidado al descartarlos tú.",
		"mesa": "Pronto podrás \"cantar\" un descarte: coger la ficha que otro acaba de tirar para completar un grupo tuyo.",
	},
	"cantar": {
		"titulo": "Cantar un descarte",
		"texto": "Cuando alguien descarta una ficha que te sirve, puedes \"cantarla\" (quedártela) aunque no sea tu turno. Solo se canta para:\n• formar un grupo de 3, 4 o 5 iguales (pung, kong o quint), usando fichas tuyas o comodines;\n• o hacer ¡Mahjong! Solo en este caso puedes cantar una ficha para una pareja o una ficha suelta.\nSi varios quieren la misma ficha, gana quien hace Mahjong. Si no, el jugador más cercano en turno a quien la descartó.",
		"mesa": "Di en voz alta \"¡La quiero!\" (en inglés, \"call\") antes de que el siguiente jugador robe. Un comodín descartado está \"muerto\": nadie puede cantarlo.",
	},
	"exponer": {
		"titulo": "Los grupos expuestos",
		"texto": "Al cantar un descarte, pones el grupo boca arriba delante de tu atril: queda EXPUESTO y ya no puedes cambiarlo. Después descartas una ficha y el turno sigue por tu derecha (los jugadores de en medio se quedan sin turno).",
		"mesa": "Los grupos expuestos dan pistas a los demás: saben a qué mano juegas. Por eso a veces conviene esperar a robar la ficha del muro en lugar de cantarla.",
	},
	"manos_ocultas": {
		"titulo": "Manos ocultas y expuestas",
		"texto": "Algunas manos de la tarjeta son OCULTAS: no puedes exponer ningún grupo para conseguirlas. En cuanto expones un grupo, esas manos quedan descartadas para ti (en la tarjeta aparecen como \"No posible\"). La única excepción: puedes cantar la última ficha si con ella haces Mahjong.",
		"mesa": "En la tarjeta oficial, cada mano lleva una X (se puede exponer) o una C (oculta, del inglés \"concealed\"). Míralo antes de cantar.",
	},
	"cambiar_comodin": {
		"titulo": "Cambiar un comodín expuesto",
		"texto": "Si un grupo expuesto (tuyo o de otro jugador) tiene un comodín y tú tienes la ficha real, en tu turno puedes cambiarla por el comodín. Te llevas un comodín, ¡que vale mucho más!",
		"mesa": "Hazlo en tu turno, después de robar y antes de descartar: pon tu ficha en el grupo y coge el comodín. Por eso conviene exponer grupos con fichas reales y guardar los comodines en la mano.",
	},
	"mahjong": {
		"titulo": "¡Mahjong!",
		"texto": "Cuando tus 14 fichas forman exactamente una mano de la tarjeta, has ganado: dices \"¡Mahjong!\" y enseñas tu mano.",
		"mesa": "Los demás comprueban tu mano con la tarjeta. Si cantas Mahjong por error y tu mano no es válida, quedas \"muerto\": ya no puedes ganar esa partida. ¡Revisa bien antes de cantarlo!",
	},
	"muro_vacio": {
		"titulo": "Partida sin ganador",
		"texto": "Si se acaban las fichas del muro y nadie ha hecho Mahjong, la partida termina en empate (\"partida muerta\").",
		"mesa": "Se vuelven a mezclar todas las fichas y se juega otra partida.",
	},
}


static func obtener(clave: String) -> Dictionary:
	return TODAS[clave]
