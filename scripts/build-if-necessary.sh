#!/bin/bash

set -e

clean_build=0
for arg in "$@"; do
  if [ "$arg" == "--clean-build" ]; then
    clean_build=1
  fi
done

source ./scripts/common.sh

if [ $clean_build -eq 1 ]; then
  echo "deleting any existing build output"
  docker run \
    --rm \
    -t \
    -v $qgis_base:/QGIS:rw \
    alpine \
    rm -rf /QGIS/build
  docker run \
    --rm \
    -it \
    -v $qgis_builder_base/.build-product:/build-product:rw \
    alpine \
    find /build-product -mindepth 1 -maxdepth 1 -not -name .gitkeep -exec rm -rf {} \;
fi

# Collect all data required to determine if a new build is required.
# Inspect both QGIS repo and this repo, in case build approach has changed.
version_data_path=$qgis_builder_base/.build-product/version-data
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
export current_version_hash=$(md5sum $version_data_path | awk '{print $1}')
built_version_path=$qgis_builder_base/.build-product/version-built
if [ -f "$built_version_path" ]; then
  built_version_hash=$(head -n 1 $built_version_path)
  if [ "$built_version_hash" == "$current_version_hash" ]; then
    echo "prior QGIS build version is still valid"
    build_required=0
  else
    echo "changes since prior QGIS build version"
  fi
else
  echo "no prior QGIS build version exists"
fi

export deps_image_name="qgis/qgis3-build-deps"

if [ $build_required -eq 1 ]; then
  echo "building QGIS deps image"
  docker build \
    --platform linux/amd64 \
    -t $deps_image_name \
    -f $qgis_base/.docker/qgis3-ubuntu-qt6-build-deps.dockerfile \
    $qgis_base

  echo "building QGIS"
  docker run \
    --rm \
    -t \
    --platform linux/amd64 \
    -v $qgis_base:/root/QGIS:rw \
    -v $qgis_builder_base/.build-product/ccache:/root/.ccache:rw \
    --env-file $qgis_base/.docker/docker-variables.env \
    --env-file $qgis_builder_base/env/common.env \
    --env-file $qgis_builder_base/env/qt-6.env \
    $deps_image_name \
    /root/QGIS/.docker/docker-qgis-build.sh

  echo "$current_version_hash" > "$built_version_path"
else
  echo "not building QGIS"
fi
