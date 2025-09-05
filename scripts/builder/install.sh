#!/bin/bash

set -e

install_root=${qgis_bin_install_root:-/usr}

ninja install

chmod +x $install_root/bin/qgis_*
