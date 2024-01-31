docker run -d \
  -p 80:80 \
  -p 443:443 \
  -v "$(pwd)/db:/app/db" \
  -v "$(pwd)/dav:/app/dav" \
  -e DEBIAN_FRONTEND=noninteractive \
  -e PYTHONUNBUFFERED=1 \
  -e FOCUS_MODE=debug \
  -e SSL=y \
  --env-file ./${1:-${FOCUS_IDENTITY}}.env \
  iainmackay/focus:${2:-${0.0.0}}
