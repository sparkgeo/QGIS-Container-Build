#!/bin/bash

set -e

force_build_arg=""
for arg in "$@"; do
  if [ "$arg" == "--force-image-build" ]; then
    force_build_arg="$arg"
  fi
done

pushd $(dirname $0)/..

source ./scripts/build-if-necessary.sh $force_build_arg

xhost +

docker run \
  --rm \
  -it \
  --platform linux/amd64 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $qgis_base/.git:/QGIS/.git:ro \
  -v $qgis_base/build:/QGIS/build:rw \
  -e DISPLAY=unix$DISPLAY \
  -w /QGIS/build \
  $qgis_image_name \
  ctest
test_result=$?

if [ $test_result -ne 0 ]; then
  echo; echo "* Test failure"
  echo "* Test logs at $qgis_base/build/Testing/Temporary/LastTest.log"; echo
fi
