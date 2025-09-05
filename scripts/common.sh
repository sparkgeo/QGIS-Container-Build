#!/bin/bash

set -e

pushd $(dirname $0)/..

export qgis_builder_base="$PWD"
export qgis_base="$(realpath ${qgis_repo_path:-$qgis_builder_base/../QGIS})"

if [ ! -d "$qgis_base" ]; then
  echo "$qgis_base not found, do you need to set \$qgis_repo_path ?"
  exit 1
fi
