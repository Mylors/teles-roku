# teles-roku 📺

Una adaptación nativa del proyecto **teles** para televisores y dispositivos **Roku TV**, escrita en **BrightScript** y **SceneGraph (XML)**. Permite acceder a transmisiones de noticias en vivo (Chile y el mundo) de forma rápida y gratuita.

---

## Características

*   **Carga Ultra Rápida**: Optimizado con jsDelivr CDN para cargar la lista de canales instantáneamente.
*   🇨🇱 **Priorización Nacional**: Los canales chilenos se muestran al principio de la rejilla por defecto.
*  **Buscador en Tiempo Real**: Teclado compacto integrado en pantalla para buscar canales chilenos e internacionales al instante.
*   **Canales Favoritos**: Marca cualquier canal como favorito presionando la tecla **Asterisco (`*`)** en tu control remoto. Tus favoritos se guardan localmente en la memoria del Roku y aparecen al principio de la app.
*   **Limpieza de Recursos**: Cierre y liberación automática de sockets de red y memoria de video al detener la reproducción.

---

## Contenido del Repositorio

```
├── manifest               # Archivo de metadatos básicos y configuración del canal
├── source/
│   └── main.brs           # Script de inicialización y ciclo de vida de la app
├── components/
│   ├── JsonTask.xml/.brs  # Petición HTTP asíncrona para cargar la lista de canales
│   └── MainScene.xml/.brs # Interfaz de usuario (grid, teclado, reproductor de video)
└── images/
    ├── channel_icon_fhd.jpg   # Icono de inicio en resolución FHD
    ├── channel_icon_hd.jpg    # Icono de inicio en resolución HD
    ├── splash_screen_fhd.jpg  # Pantalla de carga FHD
    └── splash_screen_hd.jpg   # Pantalla de carga HD
```

---

## Cómo Instalar (Sideloading)

Dado que es una app privada de uso personal, se instala usando el **Modo Desarrollador** de Roku:

### Paso 1: Activar el Modo Desarrollador en Roku
1. Con tu control remoto de Roku, presiona esta secuencia:
   * **Inicio (Home)** x3
   * **Arriba (Up)** x2
   * **Derecha (Right)** x1, **Izquierda (Left)** x1, **Derecha (Right)** x1, **Izquierda (Left)** x1, **Derecha (Right)** x1
2. En la pantalla que aparece, selecciona **Enable installer and restart**.
3. Acepta los términos de uso y crea una **contraseña de desarrollador** (anótala junto con la dirección IP de tu Roku, por ejemplo `192.168.1.50`). El dispositivo se reiniciará.

### Paso 2: Empaquetar e Instalar 
1. Descarga el archivo adjunto **[teles-roku.zip](https://github.com/Mylors/teles-roku/releases/tag/v.1.0.0)** de este release.
2. Abre un navegador web en tu computadora e ingresa a la IP de tu Roku (ej. `http://192.168.1.50`).
3. Inicia sesión con el usuario `rokudev` y la contraseña de desarrollador que creaste.
4. En la interfaz web, haz clic en **Upload**, selecciona tu archivo `.zip` y haz clic en **Install**.
5. ¡El canal de **teles** se abrirá automáticamente en tu televisor!

---

## Créditos y Agradecimientos

Este canal es un cliente alternativo de Roku y utiliza las bases de datos públicas provistas por el gran trabajo de la comunidad en los repositorios oficiales de **teles**:

*   **[@Alplox/teles](https://github.com/Alplox/teles)**: Proyecto web original y diseño general desarrollado por @Alplox.
*   **[@Alplox/json-teles](https://github.com/Alplox/json-teles)**: Repositorio oficial de la base de datos de canales y señales en formato JSON que alimenta a esta aplicación de forma dinámica.

