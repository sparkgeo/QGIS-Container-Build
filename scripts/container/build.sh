#!/bin/bash

set -e

install_root=${qgis_bin_install_root:-/usr}

cmake \
  -GNinja \
  -DUSE_CCACHE=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$install_root \
  -DCMAKE_INSTALL_RPATH=$install_root/lib \
  -DWITH_DESKTOP=ON \
  -DWITH_SERVER=ON \
  -DWITH_3D=ON \
  -DWITH_BINDINGS=ON \
  -DWITH_CUSTOM_WIDGETS=ON \
  -DBINDINGS_GLOBAL_INSTALL=ON \
  -DWITH_STAGED_PLUGINS=ON \
  -DWITH_GRASS=ON \
  -DDISABLE_DEPRECATED=ON \
  -DENABLE_TESTS=ON \
  -DWITH_QSPATIALITE=ON \
  -DWITH_APIDOC=OFF \
  -DWITH_ASTYLE=OFF \
  ..

ninja install

if [ $? -eq 0 ]; then
    echo "OK" > /QGIS/build_exit_value
else
    echo "FAILED" > /QGIS/build_exit_value
fi

chmod +x $install_root/bin/qgis_*
