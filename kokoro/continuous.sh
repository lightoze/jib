#!/bin/bash

set -e
set -x

rm -f ${HOME}/.docker/config.json

which docker-credential-desktop || true
which docker-credential-osxkeychain || true
ls -l `which docker-credential-desktop` || true
ls -l `which docker-credential-osxkeychain` || true
ls -l /Applications/Docker.app/Contents/Resources/bin/ || true

gcloud components install docker-credential-gcr

# docker-credential-gcr uses GOOGLE_APPLICATION_CREDENTIALS as the credentials key file
export GOOGLE_APPLICATION_CREDENTIALS=${KOKORO_KEYSTORE_DIR}/72743_jib_integration_testing_key

# Stops any left-over containers.
docker stop $(docker ps --all --quiet) || true
docker kill $(docker ps --all --quiet) || true

# Sets the integration testing project.
export JIB_INTEGRATION_TESTING_PROJECT=jib-integration-testing

cat ${HOME}/.docker/config.json

# Restarting Docker for Mac to get around the certificate expiration issue:
# b/112707824
# https://github.com/GoogleContainerTools/jib/issues/730#issuecomment-413603874
# https://github.com/moby/moby/issues/11534
# TODO: remove this temporary fix once b/112707824 is permanently fixed.
if [ "${KOKORO_JOB_CLUSTER}" = "MACOS_EXTERNAL" ]; then
  osascript -e 'quit app "Docker"'
  open -a Docker
  while ! docker info > /dev/null 2>&1; do sleep 1; done
fi

cat ${HOME}/.docker/config.json

mkdir -p /tmp/a
docker run --rm --entrypoint htpasswd registry:2 -Bbn user pass > /tmp/a/htpasswd
docker run --rm -d -p5000:5000 -v /tmp/a:/auth \
  -e 'REGISTRY_AUTH=htpasswd' \
  -e 'REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm' \
  -e 'REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd' \
  -e 'REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd' registry:2

docker login localhost:5000 --username user --password pass

cat ${HOME}/.docker/config.json

exit 0

cd github/jib

./gradlew clean build integrationTest --info --stacktrace
