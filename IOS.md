# Llevar el juego a iOS (iPhone y iPad)

El proyecto ya trae lo necesario para iOS:
- Preset de exportación **iOS** en `export_presets.cfg`: identificador `com.mahjongenespanol`,
  iPhone y iPad, pantalla horizontal y la declaración de que el juego no usa cifrado
  (así Apple no pregunta por «cumplimiento de exportación»).
- Ícono de 1024 × 1024 sin transparencia (`assets/icono/icono_ios_1024.png`). Godot crea
  los demás tamaños a partir de él y Apple redondea las esquinas.
- Capturas con las medidas del App Store en `tienda/capturas_ios/` (iPhone de 6,9" y iPad de 13").
- Textos de la tienda en `tienda/FICHA_TIENDA.md` (sección App Store).

## Paso 1. Cuenta de Apple Developer (una vez)
1. En https://developer.apple.com/programs pulsa **Enroll** y paga los 99 USD al año
   (como **Individual**, o como **Organization** si ya tienes empresa con número D-U-N-S).
2. Espera el correo de bienvenida.
3. Busca tu **Team ID**: en https://developer.apple.com/account → **Membership details**.
   Son 10 letras y números, por ejemplo `AB12CD34EF`.

## Paso 2. Preparar el Mac (una vez)
1. Instala **Xcode** desde la Mac App Store (es gratis y pesa mucho). Ábrelo una vez y
   deja que instale sus componentes.
2. En Xcode: **Xcode → Settings → Accounts → +** y entra con tu Apple ID de desarrollador.
3. En Godot: las plantillas de exportación que ya instalaste incluyen iOS.

## Paso 3. Exportar desde Godot
1. **Proyecto → Exportar…** y elige el preset **iOS**.
2. En **App Store Team ID** escribe tu Team ID.
3. Pulsa **Exportar Proyecto…** y guárdalo en una carpeta nueva, por ejemplo
   `Escritorio/MahjongiOS/MahjongEnEspanol` (sin «Exportar con depuración»).
   Godot crea un **proyecto de Xcode** (`MahjongEnEspanol.xcodeproj`), no una app instalable.

## Paso 4. Probar en tu iPhone o iPad
1. Abre `MahjongEnEspanol.xcodeproj` con Xcode.
2. A la izquierda pulsa el proyecto (ícono azul) → **Signing & Capabilities**:
   marca **Automatically manage signing** y elige tu **Team**.
   Si sale un aviso amarillo de «conflicting provisioning settings» o un error rojo de
   `.entitlements`: en **Build Settings** (con **All**), busca «Code Signing Identity» y pon
   **Apple Development** en Debug y en Release; y busca «Code Signing Entitlements» y deja
   el valor vacío. (El preset ya usa «Apple Development»; Xcode firma con «Distribution»
   solo al subir a App Store Connect.)
3. En el iPhone: **Ajustes → Privacidad y seguridad → Modo de desarrollador** → activar
   (se reinicia). Conéctalo al Mac por cable y acepta «Confiar en esta computadora».
4. Arriba en Xcode elige tu iPhone como destino y pulsa **▶**. El juego se instala y se abre.
5. Revisa que el menú diga la versión correcta (por ejemplo «Versión 1.0.1»).

## Paso 5. Crear la app en App Store Connect
En https://appstoreconnect.apple.com → **Apps → + → Nueva app**:
- **Plataforma:** iOS
- **Nombre:** Mahjong en Español
- **Idioma principal:** Español (México)
- **ID del paquete (Bundle ID):** `com.mahjongenespanol` (si no aparece, primero pulsa ▶
  en Xcode con la firma automática: Xcode lo registra solo)
- **SKU:** `mahjongenespanol`

## Paso 6. Subir la versión
1. En Xcode, como destino elige **Any iOS Device (arm64)**.
2. **Product → Archive**. Al terminar se abre el **Organizer**.
3. **Distribute App → App Store Connect → Upload** y acepta lo que proponga.
4. En App Store Connect, la versión aparece en **TestFlight** después de unos minutos
   (a veces una hora).

## Paso 7. TestFlight (prueba)
En **TestFlight** agrega probadores por correo. Ellos instalan la app **TestFlight** del
App Store y desde ahí el juego. Apple no exige un número mínimo de probadores ni días.

## Paso 8. Ficha de la tienda y revisión
En la pestaña **App Store** de tu app:
- **Capturas:** iPhone de 6,9" → `tienda/capturas_ios/iphone/`; iPad de 13" →
  `tienda/capturas_ios/ipad/` (en orden del 1 al 6).
- **Texto promocional, descripción, palabras clave y subtítulo:** de `tienda/FICHA_TIENDA.md`.
- **URL de soporte (obligatoria)** y **URL de la política de privacidad:** una página con
  tu correo de contacto (puede ser la misma de la política de privacidad).
- **Privacidad de la app:** «Datos no recopilados».
- **Clasificación por edad:** contesta el cuestionario (saldrá 4+).
- **Precio:** Gratis.
- En **Compilación**, elige la versión que subiste y pulsa **Enviar a revisión**.
Apple suele responder en 1 a 3 días. Si la rechaza, explica el motivo: se corrige y se reenvía.

## Cada nueva versión
Sube la versión en Godot (**Proyecto → Configuración del proyecto → Application → Config →
Version**, por ejemplo 1.0.2): iOS la usa como número de versión y de compilación. Apple no
acepta subir dos veces el mismo número.

## Cosas que ya están resueltas en el código
- Zona segura: el juego deja libre la muesca y la isla dinámica.
- No hay botón «Salir» (Apple no lo permite); el botón «atrás» solo existe en Android.
- No pide permisos ni usa internet.
