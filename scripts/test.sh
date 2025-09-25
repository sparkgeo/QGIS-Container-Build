#!/bin/bash

clean_build_arg=""
test_batch_name_arg="ALL_BUT_PROVIDERS"
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean-build)
      clean_build_arg="$1"
      shift;
      ;;
    --test-batch-name)
      test_batch_name_arg="$2"
      shift; shift
      ;;
  esac
done

pushd $(dirname $0)/..

source ./scripts/build-if-necessary.sh $clean_build_arg

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
