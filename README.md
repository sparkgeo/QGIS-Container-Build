# QGIS Container Build

This repo is intended as a side-car to support simpler QGIS builds and tests.

Building QGIS from source requires a lot of dependencies and containerising the build environment is a useful way of managing these dependencies. However, the QGIS repo does not offer much support for containerised builds and, where it does, QGIS is compiled during a container image build step. By default this does not persist any build or ccache products between builds, meaning that QGIS is compiled from scratch. This is both time-consuming and resource-intensive.

This repo uses a container to execute build steps, and retains build products in a host directory, so that subsequent builds execute much faster. It avoids building if the QGIS source code has not changed since the last build.

## Branches

There is not yet a comprehensive plan for managing branches between the two repos. Initially this repo has a `release-3_44` branch that can build the QGIS branch of the same name. Moving forwards this convention may continue, and if something changes this document should be updated.

## Usage

### Configuration

By default this repo expects the QGIS source code to be available at `./../QGIS`. If this is not correct:

```sh
# if using a relative path it should be relative to this repo's root directory
export qgis_repo_path=/path/to/QGIS/repo
```

### Build

To build QGIS:

```sh
scripts/build-if-necessary.sh
```

A new QGIS build can be forced with a flag if required:

```sh
scripts/build-if-necessary.sh --force-build
```

> [!NOTE]
> `--force-build` initiates a build in the QGIS repo, but does not guarantee full re-compilation from source. If QGIS determines that the cache in the mounted `QGIS/.build` directory is up to date then it will skip build steps. For a complete re-compile first delete the `QGIS/.build` directory.


### Run

To run QGIS, first building if necessary:

```sh
# also supports the --force-build flag
scripts/run.sh
```
