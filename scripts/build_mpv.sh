#!/bin/bash

COMMAND=$1

MPV_LOCAL_BUILD_DIR="artifacts/mpv"
MPV_BUILD_DIR="/opt/mpv/build"
DEST_OS="win32"
TARGET="x86_64-w64-mingw32.static"

MPV_CONFIGURE_OPTS="-o ${MPV_BUILD_DIR} --enable-libmpv-shared"
MPV_BUILD_OPTS=""

DOCKERFILE_TEMPLATE="Dockerfile.template"
DOCKERFILE_TEMPLATE_CONFIG="${DOCKERFILE_TEMPLATE}.json"

BUILD_IMAGE="mpv_latest"
BUILD_CONTAINER="mpv_build_env"

docker_cp_build () {
    docker cp "${BUILD_IMAGE}:${MPV_BUILD_DIR}/" ${MPV_LOCAL_BUILD_DIR}
}

stop_container () {
    docker stop $BUILD_CONTAINER
    docker rm $BUILD_CONTAINER
}

MPV_LOCAL_BUILD_DIR=$(pwd)/${MPV_LOCAL_BUILD_DIR}
cd $(dirname $0)/../$IMAGE_DIR

case $COMMAND in
    image)
        py -3 ../scripts/build_docker_template.py $DOCKERFILE_TEMPLATE $DOCKERFILE_TEMPLATE_CONFIG
        docker build --target mxebase -t $BUILD_IMAGE .
        docker build --target mxebuild -t $BUILD_IMAGE .
        docker build --target mpvbase -t $BUILD_IMAGE .
        ;;
    clean)
        [ -d ${MPV_LOCAL_BUILD_DIR} ] && rm -r ${MPV_LOCAL_BUILD_DIR}/*
      ;;
    build)
        [ ! -d ${MPV_LOCAL_BUILD_DIR} ] && mkdir -p ${MPV_LOCAL_BUILD_DIR}
        docker run --name $BUILD_CONTAINER \
          --mount type=bind,source=${MPV_LOCAL_BUILD_DIR},target=${MPV_BUILD_DIR} \
          -e DEST_OS=${DEST_OS} -e TARGET=${TARGET} \
          ${BUILD_IMAGE} \
          "./waf configure ${MPV_CONFIGURE_OPTS} && ./waf build ${MPV_BUILD_OPTS}"
      ;;
    *)
        echo "Usage $0 <build|clean|image>"
        exit 1
      ;;
esac
