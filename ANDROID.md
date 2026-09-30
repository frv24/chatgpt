# Llevar el juego a Android

El proyecto ya está preparado: nombre de paquete, versión, íconos, pantalla de carga,
botón «atrás», zona segura y la configuración de exportación (`export_presets.cfg`).
Esto es lo que falta hacer **en tu computadora**.

> Los nombres de los menús son los de Godot 4.4. Si usas una versión más nueva, pueden
> cambiar un poco. La guía oficial está en
> https://docs.godotengine.org/es/stable/tutorials/export/exporting_for_android.html

## Paso 2. Preparar tu computadora (una sola vez)

1. **Plantillas de exportación de Godot**
   En Godot: *Editor → Gestionar plantillas de exportación → Descargar e instalar*.
   Tienen que ser de la misma versión que tu Godot.

2. **Java (OpenJDK 17)**
   Descárgalo de https://adoptium.net (versión 17, «LTS») e instálalo.

3. **Android SDK**
   Lo más fácil es instalar **Android Studio** (https://developer.android.com/studio).
   Al abrirlo, en *SDK Manager* marca:
   - *Android SDK Platform-Tools*
   - *Android SDK Build-Tools* (la versión que pida tu Godot; en 4.4, la 34)
   - *Android SDK Command-line Tools*
   - la plataforma Android que pida tu Godot (en 4.4, Android 14 / API 34)

4. **Decirle a Godot dónde están**
   *Editor → Configuración del editor → Exportar → Android*:
   - *Java SDK Path*: la carpeta donde se instaló el JDK 17.
   - *Android SDK Path*: la carpeta del SDK. Android Studio la muestra en *SDK Manager*,
     arriba, en «Android SDK Location».

## Paso 3. Probar en tu teléfono

1. En el teléfono: *Ajustes → Acerca del teléfono* y toca 7 veces «Número de compilación»
   para activar las *Opciones de desarrollador*.
2. En *Opciones de desarrollador*, activa **Depuración USB**.
3. Conecta el teléfono por cable y acepta el aviso que aparece en el teléfono.
4. En Godot aparece un **icono de Android** arriba a la derecha, junto al botón ▶.
   Púlsalo: el juego se instala y se abre solo en el teléfono.

Si prefieres un archivo: *Proyecto → Exportar… → Android → Exportar proyecto*, guarda
el `.apk` y cópialo al teléfono. Godot crea sola la firma de prueba («debug»).

**Qué revisar en el teléfono:** que las fichas y los botones se toquen bien con el dedo,
que los textos se lean (prueba también «Letra grande»), que los rivales no vayan lentos,
que se oiga el sonido y que el botón «atrás» funcione como esperas.

## Paso 4. Versión para Google Play

1. **Llave de firma de publicación** (se crea una vez y NUNCA se debe perder: sin ella no
   podrás actualizar la app). En una terminal:
   ```
   keytool -v -genkey -keystore mahjong_publicacion.keystore -alias mahjong -keyalg RSA -validity 10000
   ```
   Guarda el archivo y la contraseña en dos sitios seguros. **No lo subas a GitHub.**
2. En Godot: *Proyecto → Instalar plantilla de compilación de Android*.
3. En *Proyecto → Exportar… → Android*:
   - *Gradle Build → Use Gradle Build*: activado.
   - *Gradle Build → Export Format*: **AAB** (es el formato que pide Google Play).
   - *Keystore → Release*: tu archivo `.keystore`, el alias `mahjong` y la contraseña.
   - *Gradle Build → Target SDK*: el nivel de API que exija Google Play en ese momento.
     La consola de Google Play te lo dice al subir la app; si pide uno más nuevo que el de
     tu Godot, instala esa plataforma en Android Studio y ponlo aquí (o actualiza Godot).
4. *Exportar proyecto* **sin** marcar «Exportar con depuración» → obtienes el `.aab`.
5. Súbelo a Google Play Console y completa la ficha con lo que hay en `tienda/FICHA_TIENDA.md`.

**Cada nueva versión:** sube en 1 el *Version Code* (1, 2, 3…) y cambia el *Version Name*
(1.0.1, 1.1.0…) en la exportación de Android.

## Cosas que ya están hechas en el proyecto
- Nombre del paquete `com.mahjongenespanol` y nombre visible «Mahjong en Español».
- Ícono normal y adaptable (con versión monocroma), a partir del comodín sobre rosa.
- Pantalla de carga rosa con papel picado.
- Pantalla horizontal, modo inmersivo (sin barras del sistema) y zona segura para muescas.
- Botón «atrás»: cierra ventanas, abre el menú y, desde el menú, sale.
- Sin permisos especiales: la app no usa internet ni pide acceso a nada.
- Las pruebas (`tests/`) no se incluyen en la app.
