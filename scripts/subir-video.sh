#!/usr/bin/env bash
# Sube un video en calidad completa a la rama "media" del repo público Houz28/houzites-media
# y escribe en la salida la URL pública (raw.githubusercontent.com).
#
# Uso: bash subir-video.sh <archivo.mp4> <AAAAMMDD-HHMM-rubro.mp4>
#   El nombre empieza con la fecha de PUBLICACIÓN (hora de Buenos Aires).
#
# Para que el repo no crezca: cada subida reemplaza la rama "media" por un solo commit
# sin historia que tiene el video nuevo más los videos con fecha de ayer en adelante.
# Los más viejos se caen solos. Usa --force-with-lease, así dos tareas que suben a la vez
# no se pisan: la que pierde vuelve a intentar con la rama nueva.
# Nunca toca la rama main.
set -uo pipefail

SRC=$(readlink -f "${1:?falta el archivo}")
NAME=${2:?falta el nombre final}
[[ "$NAME" =~ ^[0-9]{8}-[0-9]{4}-[a-z0-9-]+\.mp4$ ]] || { echo "ERROR: nombre inválido ($NAME). Formato: AAAAMMDD-HHMM-rubro.mp4" >&2; exit 2; }
SIZE=$(stat -c %s "$SRC")
(( SIZE < 95*1024*1024 )) || { echo "ERROR: pesa más de 95 MB (GitHub corta en 100 MB)" >&2; exit 2; }

REPO=https://github.com/Houz28/houzites-media
URL="https://raw.githubusercontent.com/Houz28/houzites-media/media/$NAME"
KEEP_FROM=$(TZ=America/Argentina/Buenos_Aires date -d yesterday +%Y%m%d)

for i in 1 2 3 4 5; do
  W=$(mktemp -d)
  if git clone -q --bare --depth 1 --filter=blob:none --single-branch --branch media "$REPO" "$W/r" 2>/dev/null; then
    cd "$W/r"
    OLD=$(git rev-parse HEAD)
    KEEP=$(git ls-tree HEAD | awk -F'\t' -v k="$KEEP_FROM" -v n="$NAME" 'substr($2,1,8) >= k && $2 != n')
  else
    git init -q --bare "$W/r" && cd "$W/r" && git remote add origin "$REPO"
    OLD=""
    KEEP=""
  fi
  BLOB=$(git hash-object -w "$SRC")
  TREE=$( { [[ -n "$KEEP" ]] && printf '%s\n' "$KEEP"; printf '100644 blob %s\t%s\n' "$BLOB" "$NAME"; } | git mktree )
  COMMIT=$(git -c commit.gpgsign=false commit-tree "$TREE" -m "Video $NAME")
  if git push -q --force-with-lease="refs/heads/media:$OLD" origin "$COMMIT:refs/heads/media" 2>"$W/err"; then
    for j in $(seq 1 24); do
      GOT=$(curl -sI "$URL" | awk 'tolower($1)=="content-length:"{print $2+0}')
      [[ "$GOT" == "$SIZE" ]] && { echo "$URL"; exit 0; }
      sleep 5
    done
    echo "ERROR: se subió pero la URL no responde con el tamaño correcto: $URL" >&2
    exit 1
  fi
  echo "intento $i falló: $(tail -2 "$W/err" | tr '\n' ' ')" >&2
  cd / && sleep $((i * 8))
done
echo "ERROR: no se pudo subir después de 5 intentos" >&2
exit 1
