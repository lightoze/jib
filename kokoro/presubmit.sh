#!/bin/bash

set -e
set -x

rm -f ${HOME}/.docker/config.json
which docker-credential-desktop || true
which docker-credential-osxkeychain || true
ls -l `which docker-credential-desktop` || true
ls -l `which docker-credential-osxkeychain` || true
ls -l /Applications/Docker.app/Contents/Resources/bin/ || true
rm -f `which docker-credential-desktop` `which docker-credential-osxkeychain`
which docker-credential-desktop || true
which docker-credential-osxkeychain || true

gcloud components install docker-credential-gcr

# Stops any left-over containers.
docker stop $(docker ps --all --quiet) || true
docker kill $(docker ps --all --quiet) || true

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

cd github/jib

cat ${HOME}/.docker/config.json || true
rm -f ${HOME}/.docker/config.json

mkdir -p /tmp/a
docker run --rm --entrypoint htpasswd registry:2 -Bbn user pass > /tmp/a/htpasswd
docker run --rm -d -p5000:5000 -v /tmp/a:/auth \
  -e 'REGISTRY_AUTH=htpasswd' \
  -e 'REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm' \
  -e 'REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd' \
  -e 'REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd' registry:2

docker login localhost:5000 --username user --password pass

exit 0

# we only run integration tests on jib-core for presubmit
./gradlew clean build :jib-core:integrationTest --info --stacktrace
