#!/bin/bash

clean_build_arg=""
test_batch_name="ALL_BUT_PROVIDERS"
test_blocklist_file=".ci/test_blocklist_qt6_ubuntu.txt"
test_identifier=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean-build)
      clean_build_arg="$1"
      shift;
      ;;
    --test-batch-name)
      test_batch_name="$2"
      shift; shift
      ;;
    --test-blocklist-file)
      test_blocklist_file="$2"
      shift; shift
      ;;
    --test-identifier)
      test_identifier="$2"
      shift; shift
      ;;
  esac
done

pushd $(dirname $0)/..

source ./scripts/build-if-necessary.sh $clean_build_arg

if [ "$test_identifier" == "" ]; then
  run_command="/root/QGIS/.docker/docker-qgis-test.sh $test_batch_name $test_blocklist_file"
else
  run_command="python3 /root/QGIS/.ci/ctest2ci.py xvfb-run ctest -V -R $test_identifier -S /root/QGIS/.ci/config_test.ctest --output-on-failure"
fi

export QGIS_WORKSPACE=$qgis_base
export QGIS_COMMON_GIT_DIR=$qgis_base
dco="docker compose --file $qgis_base/.docker/docker-compose-testing.yml"

if [ "$test_batch_name" == "ORACLE" ] || [ "$test_batch_name" == "ALL" ]; then
  dco="$dco --file $qgis_base/.docker/docker-compose-testing-oracle.yml --file $qgis_builder_base/docker-compose-testing-oracle-alt.yml"
fi
if [ "$test_batch_name" == "POSTGRES" ] || [ "$test_batch_name" == "ALL" ]; then
  dco="$dco --file $qgis_base/.docker/docker-compose-testing-postgres.yml --file $qgis_builder_base/docker-compose-testing-postgres-alt.yml"
fi
if [ "$test_batch_name" == "SQLSERVER" ] || [ "$test_batch_name" == "ALL" ]; then
  dco="$dco --file $qgis_base/.docker/docker-compose-testing-mssql.yml --file $qgis_builder_base/docker-compose-testing-mssql-alt.yml"
fi

dco="$dco --file $qgis_builder_base/docker-compose-testing.alt.yml"
dco="$dco --project-name qgis-test"

$dco run \
  --rm \
  -t \
  -w /root/QGIS \
  -e CTEST_BUILD_NAME="local-$current_version_hash" \
  qgis-deps-alt \
  $run_command

test_exit_code=$?

$dco down

exit $test_exit_code
