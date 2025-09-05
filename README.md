# QGIS Container Build

This repo is intended as a side-car to support simpler QGIS builds and tests.

Building QGIS from source requires a lot of dependencies and containerising the build environment is a useful way of managing these dependencies. However, the QGIS repo does not provide a simple way to develop and test within containers. Container supports is limited and appears to focus on CI rather than development.

This repo uses containers to execute build steps, and retains build products in a host directory, so that subsequent builds execute much faster. It avoids building if source code has not changed since the last build.

## Branches

QGIS is in the process of migrating from QT5 to QT6 and each platform requires different build steps. The `qt5` branch is intended for 3.* versions.

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

This script will build QGIS only if either this repo or the QGIS repo have changed since the last successful build. Change detection is based on each repo's last commit hash, staged changes, unstaged changes, and the contents of any untracked files.

A new QGIS build can be forced with a flag if required, bypassing change detection. This does not guarantee complete re-compilation from source as the QGIS build configuration will respect any existing build cache it previously generated.

```sh
scripts/build-if-necessary.sh --force-build
```

### Run

To run QGIS:

```sh
scripts/run.sh
```

This script will build and install QGIS if necessary, based on the same change detection described above, before running the application. 

A fresh install can be forced with a flag if required, bypassing change detection. The [build](#build) script's `--force-build` flag can also be used here, which will automatically force a fresh install.

```sh
# force fresh install of an existing build
scripts/run.sh --force-install
# force fresh build and install
scripts/run.sh --force-build
```

### Test

To execute QGIS tests:

This script will build QGIS if necessary, based on the same change detection described above.

```sh
# also supports the --force-build flag
scripts/test.sh
```
