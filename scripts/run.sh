#!/bin/bash

set -e

force_build_arg=""
for arg in "$@"; do
  if [ "$arg" == "--force-build" ]; then
    force_build_arg="$arg"
  fi
done

pushd $(dirname $0)/..

source ./scripts/build-if-necessary.sh $force_build_arg

xhost +

docker run \
  --rm \
  -it \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $qgis_builder_base/.gdal-logs:/gdal-logs:rw \
  -v $qgis_builder_base/.install-product/main:/qgis-install:rw \
  -v $qgis_builder_base/.install-product/python:/usr/local/lib/python3.12/dist-packages/qgis:rw \
  -e DISPLAY=unix$DISPLAY \
  -e CPL_DEBUG=ON \
  -e CPL_LOG=/gdal-logs/cpl.log \
  -e CPL_LOG_ERRORS=ON \
  $qgis_image_name \
  /qgis-install/bin/qgis
