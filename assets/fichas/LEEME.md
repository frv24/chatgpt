# Diseños de las fichas

Pon aquí las imágenes de las fichas. El juego las detecta solo: si existe
`bam5.png`, la ficha "Bambú 5" se dibuja con esa imagen; si no existe, se dibuja
con texto como hasta ahora. Puedes ir subiendo los diseños poco a poco.

## Formato
- **PNG** con fondo transparente fuera de la ficha (también valen SVG y WebP).
- **Tamaño: 256 × 352 píxeles** (proporción 8:11, la misma que la ficha en pantalla).
  Si quieres más calidad, usa 512 × 704. Todas las fichas deben tener el mismo tamaño.
- Solo la **cara** de la ficha, vista de frente y sin sombra: el juego añade el
  borde de selección y de consejo.
- Deja un **margen de seguridad** de unos 16 px (en 256 × 352) sin nada importante.
- Colores sRGB y menos de 200 KB por imagen.

## Recomendaciones para que se entienda bien (todas las edades)
- **Índice grande en una esquina** (el número, o N/E/O/S, D, F, J), como en los
  juegos americanos. Ayuda a quien empieza y a quien ve mal.
- Mantén un **color fijo por palo** (ahora: Nopal verde, Picado rosa, Sol naranja).
  Cada dragón va con un palo: Maguey → Nopal, Chile → Picado, Blanco → Sol.
- El **Blanco** también hace de "0" en las manos de años (2026):
  conviene que se lea bien como cero.
- Las 4 copias de una misma ficha son idénticas: basta con una imagen por ficha.

## Nombres de los archivos (43 imágenes)

Los archivos usan las claves clásicas del código; en el juego se muestran con los
nombres del diseño: `bam` = Nopal, `car` = Picado, `cir` = Sol,
`dR` = Chile, `dV` = Maguey, `dB` = Blanco, `flor` = Cempasúchil.

| Fichas | Archivos |
|---|---|
| Nopal 1 al 9 | `bam1.png` … `bam9.png` |
| Picado 1 al 9 | `car1.png` … `car9.png` |
| Sol 1 al 9 | `cir1.png` … `cir9.png` |
| Vientos | `vN.png` (Norte), `vE.png` (Este), `vO.png` (Oeste), `vS.png` (Sur) |
| Dragones | `dR.png` (Chile), `dV.png` (Maguey), `dB.png` (Blanco) |
| Flor | `flor.png` (Cempasúchil) |
| Comodín | `comodin.png` |
| Reverso (para más adelante) | `reverso.png` |

Respeta mayúsculas y minúsculas exactamente (`vN`, no `vn`).

## Cómo subirlas
Con GitHub desde el navegador:
1. Entra en el repositorio y cambia a la rama del juego.
2. Abre la carpeta `assets/fichas`.
3. Pulsa **Add file → Upload files**, arrastra las imágenes y confirma con **Commit changes**.

## Derechos
Usa solo diseños **propios o con licencia** que permita usarlos en una app
comercial. No copies fichas de juegos o apps existentes.
