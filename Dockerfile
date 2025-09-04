FROM qgis/qgis3-build-deps

# Additional run-time dependencies
RUN pip3 install --break-system-packages jinja2 pygments pexpect && apt install -y expect

# Add QGIS test runner
COPY .docker/qgis_resources/test_runner/qgis_* /usr/bin/

# Make all scripts executable
RUN chmod +x /usr/bin/qgis_*

# Add supervisor service configuration script
COPY .docker/qgis_resources/supervisor/ /etc/supervisor

# Python paths are for
# - kartoza images (compiled)
# - deb installed
# - built from git
# needed to find PyQt wrapper provided by QGIS
ARG QGIS_BIN_INSTALL_ROOT=/usr
ENV PYTHONPATH=${QGIS_BIN_INSTALL_ROOT}/share/qgis/python/:${QGIS_BIN_INSTALL_ROOT}/share/qgis/python/plugins:${QGIS_BIN_INSTALL_ROOT}/lib/python3/dist-packages/qgis:${QGIS_BIN_INSTALL_ROOT}/share/qgis/python/qgis

COPY . /QGIS

# If this directory is changed, also adapt script.sh which copies the directory
# if ccache directory is not provided with the source
RUN mkdir -p /QGIS/.ccache_image_build
ENV CCACHE_DIR=/QGIS/.ccache_image_build
RUN ccache -M 1G
RUN ccache -s

RUN git config --global --add safe.directory /QGIS
