# Mahjong Americano (en español)

Juego de Mahjong americano para todas las edades, con consejos para aprender a jugar.
Hecho con [Godot 4](https://godotengine.org) para Android e iOS (y también PC y web).

## Cómo abrirlo
1. Descarga **Godot 4.4 o superior** (versión estándar, no la ".NET").
2. Abre Godot, pulsa **Importar** y elige el archivo `project.godot` de esta carpeta.
3. Pulsa **F5** (o el botón ▶) para jugar.

## Qué hay ya hecho
- **Las 152 fichas**: barajar y repartir.
- **Tarjeta de principiante**: 7 manos inventadas al estilo de la tarjeta oficial.
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
- **Lecciones ("¿por qué?")**, para aprender aquí y luego jugar en una mesa real:
  - La primera vez que pasa algo (el Charleston, cada tipo de pase, los turnos, el Mahjong…)
    sale una explicación con un recuadro "En la mesa real".
  - El botón **¿Por qué?** explica el paso actual en cualquier momento.
  - El botón **Reglas** reúne todas las lecciones para repasarlas.
  - El interruptor **Explicaciones** las desactiva; la app recuerda cuáles ya viste.
- **Consejos**:
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
  tarjeta.gd             Las manos ganadoras (edítalas aquí)
  validador.gd           ¿Es mano ganadora? ¿Cuántas fichas faltan?
  asesor.gd              Qué fichas sobran (lo usan los rivales y «Sugerir»)
  charleston.gd          Los pases del Charleston
  partida.gd             Reparto, turnos y final de la partida
  lecciones.gd           Los textos del "¿por qué?" (edítalos aquí)
scripts/ui/              Todo lo que se ve en pantalla
  ficha_visual.gd        Cómo se dibuja una ficha
  main.gd                La pantalla de juego
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
- [ ] Cantar descartes (pung, kong) y mostrar los grupos expuestos
- [ ] Tutorial interactivo y niveles de ayuda (Aprendiz, Intermedio, Experto)
- [ ] Dibujos de las fichas, sonidos y animaciones
- [ ] Exportar a Android (Proyecto > Exportar) y después a iOS
