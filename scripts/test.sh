#!/bin/bash

force_build_arg=""
test_batch_name_arg=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --force-build)
      force_build_arg="$1"
      shift;
      ;;
    --test-batch-name)
      test_batch_name_arg="$2"
      shift; shift
      ;;
  esac
done

pushd $(dirname $0)/..

source ./scripts/build-if-necessary.sh $force_build_arg

mkdir -p /tmp/webdav_tests && chmod 777 /tmp/webdav_tests
mkdir -p /tmp/minio_tests/test-bucket && chmod -R 777 /tmp/minio_tests

export QGIS_WORKSPACE=$qgis_base
export QGIS_COMMON_GIT_DIR=$qgis_base
dco="docker compose --file $qgis_base/.docker/docker-compose-testing.yml --file $qgis_builder_base/docker-compose-testing.alt.yml --project-name qgis-test"
$dco run \
  --rm \
  -w /root/QGIS \
  -e CTEST_BUILD_NAME="local-$current_version_hash" \
  qgis-deps-alt \
  /root/QGIS/.docker/docker-qgis-test.sh $test_batch_name_arg

test_exit_code=$?

$dco down

exit $test_exit_code
