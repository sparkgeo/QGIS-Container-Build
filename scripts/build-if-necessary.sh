#!/bin/bash

set -e

force_build=0
for arg in "$@"; do
  if [ "$arg" == "--force-image-build" ]; then
    force_build=1
  fi
done

source ./scripts/common.sh

# Collect all data required to determine if a new build is required.
# Inspect both QGIS repo and this repo, in case build approach has changed.
version_data_path=$qgis_builder_base/.install-product/version-data
echo "" > $version_data_path
declare -a repo_paths=("$qgis_base" "$qgis_builder_base")
for repo_path in "${repo_paths[@]}"; do
  pushd $repo_path
  echo "Repo: $repo_path" >> $version_data_path
  # Include latest commit hash.
  git rev-parse HEAD >> $version_data_path
  # Include staged and unstaged changes.
  git diff HEAD >> $version_data_path
  # Include content of any untracked and not-ignored files.
  git ls-files --others --exclude-standard | xargs -I {} sh -c "echo Untracked File: {} >> $version_data_path && cat {} >> $version_data_path"
  popd
done

build_required=1
current_version_hash=$(md5sum $version_data_path | awk '{print $1}')
built_version_path=$qgis_builder_base/.install-product/version
if [ $force_build -eq 1 ]; then
  echo "forcing image build"
else
  if [ -f "$built_version_path" ]; then
    built_version_hash=$(head -n 1 $built_version_path)
    if [ "$built_version_hash" == "$current_version_hash" ]; then
      echo "prior image build version is still valid"
      build_required=0
    else
      echo "changes since prior image build version"
    fi
  else
    echo "no prior image build version exists"
  fi
fi

export qgis_image_name=qgis/qgis-local

if [ $build_required -eq 1 ]; then
  echo "building image"
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
  echo "not building image"
fi
