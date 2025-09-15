#!/bin/bash

force_build_arg=""
test_batch_name_arg="ALL_BUT_PROVIDERS"
test_identifier=""

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
    --test-identifier)
      test_identifier="$2"
      shift; shift
      ;;
  esac
done

pushd $(dirname $0)/..

source ./scripts/build-if-necessary.sh $force_build_arg

if [ "$test_identifier" == "" ]; then
  run_command="/root/QGIS/.docker/docker-qgis-test.sh $test_batch_name_arg"
else
  run_command="python3 /root/QGIS/.ci/ctest2ci.py xvfb-run ctest -V -R $test_identifier -S /root/QGIS/.ci/config_test.ctest --output-on-failure"
fi

export QGIS_WORKSPACE=$qgis_base
export QGIS_COMMON_GIT_DIR=$qgis_base
dco="docker compose --file $qgis_base/.docker/docker-compose-testing.yml --file $qgis_builder_base/docker-compose-testing.alt.yml --project-name qgis-test"
$dco run \
  --rm \
  -w /root/QGIS \
  -e CTEST_BUILD_NAME="local-$current_version_hash" \
  qgis-deps-alt \
  $run_command

test_exit_code=$?

$dco down

exit $test_exit_code
