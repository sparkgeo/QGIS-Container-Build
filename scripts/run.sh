#!/bin/bash

set -e

force_build_arg=""
force_install=0
for arg in "$@"; do
  if [ "$arg" == "--force-build" ]; then
    force_build_arg="$arg"
    force_install=1
  fi
  if [ "$arg" == "--force-install" ]; then
    force_install=1
  fi
done

pushd $(dirname $0)/..

source ./scripts/build-if-necessary.sh $force_build_arg

qgis_runner_image_name=qgis/qgis-runner

install_required=1
installed_version_path=$qgis_builder_base/.build-product/version-installed
if [ $force_install -eq 1 ]; then
  echo "forcing QGIS install"
else
  if [ -f "$installed_version_path" ]; then
    installed_version_hash=$(head -n 1 $installed_version_path)
    if [ "$installed_version_hash" == "$current_version_hash" ]; then
      echo "prior QGIS install version is still valid"
      install_required=0
    else
      echo "changes since prior QGIS install version"
    fi
  else
    echo "no prior QGIS install version exists"
  fi
fi

if [ $install_required -eq 1 ]; then
  docker build \
    -t $qgis_runner_image_name \
    -f $qgis_builder_base/Dockerfile.runner \
    --build-arg QGIS_BIN_INSTALL_ROOT=/qgis-install \
    $qgis_base

  docker run \
    --rm \
    -t \
    --platform linux/amd64 \
    -v $qgis_base:/root/QGIS:rw \
    -v $qgis_builder_base/.build-product/main:/qgis-install:rw \
    -v $qgis_builder_base/.build-product/python:/usr/local/lib/python3.12/dist-packages/qgis:rw \
    -v $qgis_builder_base/scripts/builder:/builder-scripts:ro \
    -e qgis_bin_install_root=/qgis-install \
    -w /root/QGIS/build \
    $qgis_runner_image_name \
    /builder-scripts/install.sh

  echo "$current_version_hash" > "$installed_version_path"
else
  echo "not installing QGIS"
fi

xhost +

docker run \
  --rm \
  -it \
  --platform linux/amd64 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $qgis_builder_base/.gdal-logs:/gdal-logs:rw \
  -v $qgis_builder_base/.build-product/main:/qgis-install:rw \
  -v $qgis_builder_base/.build-product/python:/usr/local/lib/python3.12/dist-packages/qgis:rw \
  -e DISPLAY=unix$DISPLAY \
  -e CPL_DEBUG=ON \
  -e CPL_LOG=/gdal-logs/cpl.log \
  -e CPL_LOG_ERRORS=ON \
  $qgis_runner_image_name \
  /bin/bash
  # /qgis-install/bin/qgis
