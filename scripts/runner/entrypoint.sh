#!/bin/bash

set -e

chown -R $QGIS_USER: /home/$QGIS_USER/.local

exec gosu $QGIS_USER "$@"
