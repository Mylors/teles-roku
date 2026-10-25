# teles-roku 📺

Cliente nativo del proyecto **teles** para televisores y dispositivos **Roku TV**, escrito en **BrightScript** y **SceneGraph (XML)**. Permite ver transmisiones de televisión en vivo de Chile y el mundo de forma rápida, gratuita y adaptada al control remoto.

---

## Novedades (v1.1.0)

*   **Interfaz rediseñada estilo Streaming**: Nuevo panel lateral de navegación con filtros por sección (*Todo, Favoritos, Chile, Internacional, Noticias, General, Música* y *Cultura*) y grilla `4×3` de tarjetas oscuras en acabado mate con acentos morados sobrios.
*   **Logos limpios y avatares automáticos**: Escalado proporcional (`scaleToFit`) para evitar logos deformados y generación automática de monogramas cuando un canal no cuenta con imagen compatible en Roku.
*   **Buscador en ventana modal**: Teclado compacto bajo demanda, insensible a tildes y capaz de filtrar por nombre de canal, país o categoría sin ocupar espacio fijo en la pantalla principal.
*   **Zapping y respaldo automático de señales**: Cambio directo de canal en pantalla completa con **Arriba/Abajo** y salto automático a señales secundarias (`m3u8`) si la señal principal falla.
*   **Correcciones de estabilidad y recursos**: Eliminación de canales duplicados en favoritos, aislamiento de foco entre pantallas, manejo de errores de red con opción de reintento y optimización de imágenes a las resoluciones oficiales del SDK de Roku.

---

## Características Principales

*   🇨🇱 **Priorización Nacional**: En la vista general (*Todo*), tus favoritos aparecen primero, seguidos por los canales chilenos y luego los internacionales, sin duplicados.
*   ★ **Canales Favoritos Persistentes**: Guarda o quita cualquier canal con la tecla **Asterisco (`*`)**; tu selección queda almacenada en el registro local del Roku.
*   ⚡ **Carga Asíncrona Optimizada**: Descarga comprimida desde jsDelivr CDN con control de tiempo de espera y reintento directo con `OK`.
*   🧹 **Liberación de Memoria**: Detención limpia del reproductor HLS y liberación de recursos al volver a la guía.

---

## Controles del Control Remoto

| Contexto | Tecla | Acción |
| :--- | :--- | :--- |
| **Grilla de canales** | `OK` | Reproducir canal en vivo |
| **Grilla de canales** | `*` (Opciones) | Agregar o quitar canal de Favoritos |
| **Grilla de canales** | `◀` (en primera columna) / `Atrás` | Pasar al menú lateral de categorías |
| **Menú lateral** | `▲` / `▼` | Explorar categorías al instante |
| **Menú lateral** | `OK` en **Buscar** | Abrir el modal de búsqueda |
| **Modal de búsqueda** | `Atrás` | Cerrar teclado e ir a los resultados |
| **Modal de búsqueda** | `*` (Opciones) | Limpiar texto de búsqueda |
| **Reproductor en vivo** | `▲` / `▼` | Hacer *zapping* al canal anterior o siguiente |
| **Reproductor en vivo** | `↺` (*Replay*) | Alternar señal alternativa (si el canal tiene varias) |
| **Reproductor en vivo** | `Atrás` | Detener transmisión y volver a la guía |

---

## Estructura del Proyecto

```text
├── manifest                       # Metadatos, íconos, splash y resolución FHD del canal
├── source/
│   └── main.brs                   # Inicialización de roSGScreen y ciclo de vida principal
├── components/
│   ├── JsonTask.xml/.brs          # Descarga HTTP asíncrona con timeout y validación
│   ├── SidebarItem.xml/.brs       # Ítem personalizado del menú lateral con contadores
│   ├── ChannelCard.xml/.brs       # Tarjeta de canal con logo proporcional y avatar fallback
│   └── MainScene.xml/.brs         # Escena principal, filtros, modal de búsqueda y reproductor
└── images/
    ├── channel_icon_fhd/hd.jpg    # Íconos del canal en norma Roku (540×405 y 290×218)
    ├── splash_screen_fhd/hd.jpg   # Pantallas de carga (1920×1080 y 1280×720)
    └── ui/                        # Gráficos ligeros de interfaz (tarjetas, modales e íconos)
```

---

## Cómo Instalar (Sideloading)

Dado que es una aplicación de instalación directa, se carga mediante el **Modo Desarrollador** de Roku:

### Paso 1: Activar el Modo Desarrollador en Roku
1. Con tu control remoto de Roku, presiona esta secuencia:
   * **Inicio (Home)** ×3
   * **Arriba (Up)** ×2
   * **Derecha (Right)** ×1, **Izquierda (Left)** ×1, **Derecha (Right)** ×1, **Izquierda (Left)** ×1, **Derecha (Right)** ×1
2. En la pantalla que aparece, selecciona **Enable installer and restart**.
3. Acepta los términos de uso y define una **contraseña de desarrollador** (anótala junto con la dirección IP de tu Roku, por ejemplo `192.168.1.50`). El dispositivo se reiniciará.

### Paso 2: Empaquetar e Instalar
1. Descarga el archivo `.zip` desde la sección **[Releases](https://github.com/Mylors/teles-roku/releases)** (o comprime directamente en la raíz de un `.zip` el archivo `manifest` junto a las carpetas `components`, `images` y `source`).
2. Abre un navegador web en tu computadora e ingresa a la IP de tu Roku (ej. `http://192.168.1.50`).
3. Inicia sesión con el usuario `rokudev` y la contraseña de desarrollador que creaste.
4. En la interfaz web, haz clic en **Upload**, selecciona el archivo `.zip` y presiona **Install**.
5. ¡El canal **teles** se abrirá automáticamente en tu televisor!

---

## Créditos y Agradecimientos

Este proyecto es un cliente alternativo para Roku alimentado por los datos públicos mantenidos por la comunidad en los repositorios oficiales de **teles**:

*   **[@Alplox/teles](https://github.com/Alplox/teles)**: Proyecto web original e idea general desarrollada por @Alplox.
*   **[@Alplox/json-teles](https://github.com/Alplox/json-teles)**: Base de datos dinámica de canales y señales en formato JSON utilizada por esta aplicación.
