#!/bin/bash

set -e

force_build=0
for arg in "$@"; do
  if [ "$arg" == "--force-build" ]; then
    force_build=1
  fi
done

source ./scripts/common.sh

pushd $qgis_base
# collect all data required to determine if a new build is required
version_data_path=$qgis_builder_base/.install-product/version-data
git rev-parse HEAD > $version_data_path
git diff HEAD >> $version_data_path
git ls-files --others --exclude-standard | xargs -I {} sh -c "echo Untracked File: {} >> $version_data_path && cat {} >> $version_data_path"
popd

build_required=1
current_version_hash=$(md5sum $version_data_path | awk '{print $1}')
built_version_path=$qgis_builder_base/.install-product/version
if [ $force_build -eq 1 ]; then
  echo "forcing build"
else
  if [ -f "$built_version_path" ]; then
    built_version_hash=$(head -n 1 $built_version_path)
    if [ "$built_version_hash" == "$current_version_hash" ]; then
      echo "prior build version is still valid"
      build_required=0
    else
      echo "changes since prior build version"
    fi
  else
    echo "no prior build version exists"
  fi
fi

export qgis_image_name=qgis/qgis-local

if [ $build_required -eq 1 ]; then
  echo "building"
  docker build \
    -t qgis/qgis3-build-deps \
    -f $qgis_base/.docker/qgis3-qt5-build-deps.dockerfile \
    $qgis_base

  host_build_dir=$qgis_base/build
  mkdir -p $host_build_dir

  docker build \
    -t $qgis_image_name \
    -f $qgis_builder_base/Dockerfile \
    --build-arg QGIS_BIN_INSTALL_ROOT=/qgis-install \
    $qgis_base

  docker run \
    --rm \
    -it \
    -v $qgis_builder_base/scripts/container/build.sh:/build.sh:ro \
    -v $host_build_dir:/QGIS/build:rw \
    -v $qgis_builder_base/.install-product/main:/qgis-install:rw \
    -v $qgis_builder_base/.install-product/python:/usr/local/lib/python3.12/dist-packages/qgis:rw \
    -e LANG=C.UTF-8 \
    -e qgis_bin_install_root=/qgis-install \
    -w /QGIS/build \
    $qgis_image_name \
    /build.sh

  echo "$current_version_hash" > "$built_version_path"
else
  echo "not building"
fi
