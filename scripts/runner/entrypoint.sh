#!/bin/bash

set -e

share_dir="/home/$QGIS_USER/.local/share"
mkdir -p $share_dir
chown -R $QGIS_USER: $share_dir

exec gosu $QGIS_USER "$@"
