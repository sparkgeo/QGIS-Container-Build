#!/bin/bash

set -e

chmod -R 777 /tmp/webdav_tests_root/webdav_tests

# defer to default entrypoint
exec /docker-entrypoint.sh "$@"
