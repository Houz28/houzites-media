# houzites-media

Videos de Houzites en calidad completa, para que TikTok (Zernio) e Instagram (Windsor) los bajen por URL pública.

- Los videos van en la rama **`media`**, nunca en `main`.
- URL de cada video: `https://raw.githubusercontent.com/Houz28/houzites-media/media/AAAAMMDD-HHMM-rubro.mp4`
- Se suben con `bash scripts/subir-video.sh <archivo.mp4> <AAAAMMDD-HHMM-rubro.mp4>`, que imprime la URL.
- La rama `media` guarda solo los videos con fecha de ayer en adelante y no tiene historia: cada subida la reemplaza por un solo commit. Así el repo no crece. Los videos viejos se caen solos (el original queda en el mensaje que la tarea le manda a Bruno).
