# Mahjong Americano (en español)

Juego de Mahjong americano para todas las edades, con consejos para aprender a jugar.
Hecho con [Godot 4](https://godotengine.org) para Android e iOS (y también PC y web).

## Cómo abrirlo
1. Descarga **Godot 4.4 o superior** (versión estándar, no la ".NET").
2. Abre Godot, pulsa **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Pulsa **F5** (o el botón ▶) para jugar.

## Qué hay ya hecho
- **Las 152 fichas**: barajar y repartir.
- **Fichas con diseño propio** (tema mexicano): palos Nopal, Picado y Sol; dragones Chile, Maguey y Blanco; flores de cempasúchil.
- **Tarjeta 2026**: 45 manos inventadas al estilo de la tarjeta oficial, en 9 secciones
  (2026, 2468, Números iguales, Quints, Escaleras, 13579, Vientos y dragones, 369, Parejas).
  El botón **Tarjeta 2026** la abre con diseño mexicano (papel picado) y cada mano dibujada
  con las fichas del juego; tocando una mano la eliges como objetivo.
- **Validador de manos**, que ya aplica las reglas de los comodines: solo valen en grupos de 3 o más.
- **Charleston completo**, guiado paso a paso:
  - Primer Charleston (derecha, enfrente, izquierda).
  - Segundo Charleston opcional (izquierda, enfrente, derecha).
  - Pase de cortesía de 0 a 3 fichas.
  - Los comodines no se pueden pasar, y las fichas que recibes se marcan en amarillo.
- **Partida por turnos contra 3 rivales de la máquina**:
  - El Este empieza con 14 fichas y descarta sin robar; el turno pasa a la derecha.
  - Los rivales roban, descartan y pueden ganar. Si gana uno, ves su mano.
  - Cada descarte muestra quién lo hizo.
  - El puesto de Este rota en cada partida.
- **Cantar descartes**:
  - Si un descarte te sirve, el juego te ofrece «Cantar pung/kong/quint» o «¡Mahjong!» y te dice cuánto te acerca.
  - Los grupos expuestos se ven sobre la mesa (los tuyos encima de tu mano, los de los rivales a la izquierda).
  - Se aplica la preferencia: el Mahjong gana, y si no, el jugador más cercano en turno.
  - Las manos ocultas pasan a «No posible» cuando expones un grupo.
  - Los rivales también cantan, y un comodín descartado no se puede cantar.
- **Cambiar comodines expuestos**: en tu turno, cambias la ficha real por el comodín de un grupo expuesto.
- **Lecciones ("¿por qué?")**, para aprender aquí y luego jugar en una mesa real:
  - La primera vez que pasa algo (el Charleston, cada tipo de pase, los turnos, el Mahjong…)
    sale una explicación con un recuadro "En la mesa real".
  - El botón **¿Por qué?** explica el paso actual en cualquier momento.
  - El botón **Reglas** reúne todas las lecciones para repasarlas.
  - El interruptor **Explicaciones** las desactiva; la app recuerda cuáles ya viste.
- **Tutorial «Aprender a jugar»**: una partida preparada de 15 pasos con un globo de ayuda.
  Lo que hay que tocar brilla en amarillo y solo eso funciona. Enseña la mano, la tarjeta,
  el Charleston, cantar, descartar y robar, y termina con tu primer Mahjong.
  Sale solo la primera vez y después está en «Nueva partida». Sus textos y fichas están en
  `scripts/logica/tutorial.gd`.
- **4 niveles** (se eligen en «Nueva partida»; se configuran en `scripts/logica/niveles.gd`):
  - **Fácil**: todas las ayudas y rivales tranquilos (no exponen grupos y a veces tiran sin pensar).
  - **Normal**: todas las ayudas y rivales que juegan de verdad.
  - **Intermedio**: sin bordes verdes ni orden por cercanía, 3 sugerencias por partida, con puntos y marcador.
  - **Experto**: sin ayudas, puedes cantar cualquier descarte que permitan las reglas y los rivales
    se defienden (no tiran fichas que completan tus grupos expuestos). Con puntos y marcador.
- **Puntos y marcador** (Intermedio y Experto): quien descarta la ficha ganadora paga doble,
  si ganas robando todos pagan doble y una mano sin comodines vale el doble.
- **Consejos** (Fácil y Normal):
  - Las manos de la tarjeta se ordenan según cuántas fichas te faltan.
  - Las fichas que te sirven llevan borde verde; las que no, se ven apagadas.
  - Cada mano trae su explicación y un consejo.
  - El botón **Sugerir** te dice qué fichas pasar o descartar, y por qué.
- **Controles táctiles**: tocas una ficha para seleccionarla y la arrastras para reordenar tu mano.

## Cómo está organizado
```
project.godot            Configuración (pantalla horizontal, 1280x720)
scenes/main.tscn         Escena principal
scripts/logica/          Reglas del juego (no dibujan nada)
  ficha.gd               Una ficha
  mazo.gd                Las 152 fichas: barajar y repartir
  tarjeta.gd             Las 45 manos de la Tarjeta 2026 (edítalas aquí)
  validador.gd           ¿Es mano ganadora? ¿Cuántas fichas faltan?
  asesor.gd              Qué fichas sobran (lo usan los rivales y «Sugerir»)
  charleston.gd          Los pases del Charleston
  partida.gd             Reparto, turnos y final de la partida
  lecciones.gd           Los textos del "¿por qué?" (edítalos aquí)
  niveles.gd             Los 4 niveles y sus ayudas (edítalos aquí)
  tutorial.gd            La partida guiada: fichas preparadas y textos de cada paso
scripts/ui/              Todo lo que se ve en pantalla
  ficha_visual.gd        Cómo se dibuja una ficha
  main.gd                La pantalla de juego
  ventana_tarjeta.gd     La ventana «Tarjeta 2026»
  papel_picado.gd        El adorno de papel picado
tests/test_logica.gd     Pruebas automáticas de las reglas
```

La lógica está separada de los gráficos a propósito. Así puedes cambiar el aspecto
(poner dibujos de verdad en las fichas, por ejemplo) sin romper las reglas.

## Pruebas automáticas
Desde una terminal, en esta carpeta:
```
godot --headless --import
godot --headless --script res://tests/test_logica.gd
```
Debe terminar con `TODAS LAS PRUEBAS PASARON`. Si cambias la tarjeta o el validador,
ejecútalas otra vez.

## Aviso sobre la tarjeta oficial
La tarjeta de la National Mah Jongg League tiene derechos de autor y cambia cada año,
así que **no se debe copiar en la app**. Las manos de `tarjeta.gd` son inventadas.

## Próximos pasos
- [x] El Charleston, guiado paso a paso
- [ ] El "pase a ciegas" del Charleston (pasar fichas recibidas sin mirarlas)
- [x] Que los 3 rivales jueguen turnos: robar y descartar
- [x] Lecciones con el porqué de cada regla y cómo se hace en la mesa real
- [x] Cantar descartes (pung, kong, quint, Mahjong) y mostrar los grupos expuestos
- [x] Cambiar comodines expuestos
- [x] Niveles Fácil, Normal, Intermedio y Experto, con puntos y marcador en los dos últimos
- [x] Tutorial interactivo «Aprender a jugar»
- [x] Diseños propios de las fichas (tema mexicano: Nopal, Picado, Sol…; ver `assets/fichas/LEEME.md`)
- [ ] Sonidos y animaciones
- [ ] Exportar a Android (Proyecto > Exportar) y después a iOS
