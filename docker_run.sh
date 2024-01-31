if [ -f "./env.sh" ]; then
    . "./env.sh"
fi
echo "..Running container version ${FOCUS_VERSION?--FOCUS_VERSION is not defined}"
echo "..Using identity: ${FOCUS_IDENTITY?--FOCUS_IDENTITY is not defined}"
if [ ! -f "${FOCUS_IDENTITY}.env" ]; then
    echo "File ${FOCUS_IDENTITY}.env does not exist."
    exit 1
fi
if [ -z "${FOCUS_DOMAIN}" ]; then
  echo "..Running without SSL"
  unset cert_clause
  unset key_clause
else
  echo "..Running with domain: ${FOCUS_DOMAIN}"
  cert_clause="-v ${SSL_CERT_PATH:-/etc/letsencrypt/live/${FOCUS_DOMAIN}/fullchain.pem}:/app/domain.crt"
  key_clause="-v ${SSL_KEY_PATH:-/etc/letsencrypt/live/${FOCUS_DOMAIN}/privkey.pem}:/app/domain.key"
fi
if [ -z "${DOCKER_PULL_PASSWORD}" ]; then
  echo ".. DOCKER_PULL_PASSWORD is not defined"
  exit 1
fi

docker login -u iainmackay -p $DOCKER_PULL_PASSWORD
docker run -d \
  --name focus \
  -p 80:80 \
  -p 443:443 \
  -v "${DB_PATH:-$(pwd)/db}:/app/db" \
  -v "${DAV_PATH:-$(pwd)/dav}:/app/dav" \
  $cert_clause \
  $key_clause \
  -e DEBIAN_FRONTEND=noninteractive \
  -e PYTHONUNBUFFERED=1 \
  -e FOCUS_MODE=debug \
  -e SSL=y \
  --env-file ./${FOCUS_IDENTITY}.env \
  iainmackay/focus:${FOCUS_VERSION}
