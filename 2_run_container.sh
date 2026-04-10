export MSYS_NO_PATHCONV=1

CONTAINER_NAME=ubuntu
IMAGE_NAME=docker.io/joelkim/ubuntu:latest

echo "Stop Container..."
if podman container ls -af "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep ${CONTAINER_NAME} ; then
    running=$(podman inspect --format="{{ .State.Running }}" ${CONTAINER_NAME})
    if [ "$running" = "true" ] ; then
     podman stop ${CONTAINER_NAME}
    fi
fi

echo "Delete Container..."
if podman container ls -af "name=${CONTAINER_NAME}" --format "{{.Names}}" | grep ${CONTAINER_NAME} ; then
 podman rm -fv ${CONTAINER_NAME}
else
    echo "No container ${CONTAINER_NAME} exists."
fi

podman run -itd \
    --privileged \
    --hostname localhost \
    --name=ubuntu \
    -v ~/Work:/home/user/Work \
    -p 8000:8000 \
    -p 8080:8080 \
    -p 8888:8888 \
    "$@" \
    ${IMAGE_NAME} \
    /bin/bash
