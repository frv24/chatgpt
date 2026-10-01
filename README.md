# Mahjong en Español

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
  - **Pase a ciegas**: lo que recibes en el pase de enfrente llega boca abajo (con tu reverso).
    En el último pase de cada Charleston puedes pasar esas fichas sin mirarlas, o pulsar
    «Mirar fichas» para recogerlas.
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
  - **Intermedio**: sin bordes verdes ni orden por cercanía, pero con entrenador y 6 sugerencias
    por partida; con puntos y marcador.
  - **Experto**: sin ayudas, puedes cantar cualquier descarte que permitan las reglas y los rivales
    se defienden (no tiran fichas que completan tus grupos expuestos). Con puntos y marcador.
- **Puntos y marcador** (Intermedio y Experto): quien descarta la ficha ganadora paga doble,
  si ganas robando todos pagan doble y una mano sin comodines vale el doble.
- **Entrenador** (Fácil, Normal e Intermedio): consejos que salen solos, sin pedirlos:
  - «Te faltan»: las fichas exactas que te faltan para tu objetivo, dibujadas.
  - Al robar: si la ficha te sirve o puedes tirarla.
  - Antes de descartar: avisos si tiras un comodín (pide confirmación), una ficha que te sirve
    o una que completaría el grupo expuesto de un rival.
  - Si otra mano de la tarjeta está bastante más cerca que tu objetivo, o te falta solo una ficha.
  - Qué significa que un rival exponga un grupo, y consejos en cada paso del Charleston.
  - Los textos están en `scripts/logica/entrenador.gd`.
- **Consejos** (Fácil y Normal):
  - Las manos de la tarjeta se ordenan según cuántas fichas te faltan.
  - Las fichas que te sirven llevan borde verde; las que no, se ven apagadas.
  - Cada mano trae su explicación y un consejo.
  - El botón **Sugerir** te dice qué fichas pasar o descartar, y por qué.
- **Menú principal** con papel picado y un abanico de tus fichas: Jugar, Aprender a jugar,
  Tarjeta 2026, Reglas y **Ajustes** (sonido, volumen, velocidad de los rivales, animaciones
  y **letra grande**, que agranda un 20% todos los textos para leer mejor).
- **Sonidos** generados por el propio juego (sin archivos): ficha en la mesa, robar, pasar,
  cantar, aviso de turno y fanfarria de Mahjong. Si pones un sonido grabado con el mismo nombre
  en `assets/sonidos/` (por ejemplo `mahjong.ogg`), se usa ese.
- **Animaciones**: las fichas nuevas y los descartes aparecen con un pequeño salto, y el Mahjong
  se celebra con confeti de colores del papel picado.
- **La mesa vista desde arriba**: tú abajo, Derecha, Enfrente e Izquierda en su lado, cada uno con
  su viento (Este, Sur, Oeste, Norte) y su atril con tu reverso. En el Charleston, unas flechas
  enseñan hacia dónde van las fichas (la tuya en amarillo) y se ven viajar al pasar; al jugar,
  brilla quien tiene el turno y en el centro se ve la última ficha descartada, con una
  línea hacia quien la tiró, y cuántas quedan en el muro. Los descartes van en pequeño al lado.
- **Tarjeta para aprender** (Fácil, Normal e Intermedio): primero salen las manos a las que más te
  acercas, dibujadas con tus fichas encendidas y las que te faltan apagadas («Tienes 9 de 14»).
  El botón «Ver por secciones» la muestra como la tarjeta impresa.
- **Controles táctiles**: fichas grandes en tu mano; al tocar una ficha (o un descarte) se ve en
  grande un momento con su nombre; la arrastras para reordenar tu mano.
- **Textos en español de México.**

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
  entrenador.gd          Los consejos automáticos (edítalos aquí)
scripts/ui/              Todo lo que se ve en pantalla
  ficha_visual.gd        Cómo se dibuja una ficha
  main.gd                La pantalla de juego
  ventana_tarjeta.gd     La ventana «Tarjeta 2026»
  mesa.gd                La mesa vista desde arriba (asientos, vientos y flechas del Charleston)
  papel_picado.gd        El adorno de papel picado
  menu_principal.gd      La pantalla de inicio y los Ajustes
  sonidos.gd             Los sonidos (generados con código)
  celebracion.gd         El confeti y el letrero de ¡Mahjong!
tests/test_logica.gd     Pruebas automáticas de las reglas
herramientas/            Genera el ícono redondeado y la pantalla de carga (no va en la app)
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
- [x] El "pase a ciegas" del Charleston (pasar fichas recibidas sin mirarlas)
- [x] Letra grande en los ajustes
- [x] Que los 3 rivales jueguen turnos: robar y descartar
- [x] Lecciones con el porqué de cada regla y cómo se hace en la mesa real
- [x] Cantar descartes (pung, kong, quint, Mahjong) y mostrar los grupos expuestos
- [x] Cambiar comodines expuestos
- [x] Niveles Fácil, Normal, Intermedio y Experto, con puntos y marcador en los dos últimos
- [x] Tutorial interactivo «Aprender a jugar»
- [x] Diseños propios de las fichas (tema mexicano: Nopal, Picado, Sol…; ver `assets/fichas/LEEME.md`)
- [x] Sonidos, animaciones, menú principal, ajustes y atriles con el reverso
- [x] Preparación para Android: ícono, pantalla de carga, paquete `com.mahjongenespanol`,
      botón «atrás», zona segura y `export_presets.cfg`
- [ ] Probar en un teléfono y publicar en Google Play (guía en `ANDROID.md`,
      textos e imágenes de la tienda en `tienda/`)
- [ ] iOS
