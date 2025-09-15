# QGIS Container Build

This repo acts as a side-car to support simpler QGIS builds and tests.

Building QGIS from source requires a lot of dependencies and containerising the build environment is a useful way of managing these dependencies. However, the QGIS repo does not provide a simple way to develop and test within containers. Container supports is limited and appears to focus on CI rather than development.

This repo uses containers to execute build steps, and retains build products in a host directory, so that subsequent builds execute much faster and build products can be reused without rebuilding. It avoids building if source code has not changed since the last build.

## Roadmap

Ideally this repo would eventually be incorporated into the main QGIS repo to better support container-based development, however that will require some discussion. Until that happens, this repo's development will be driven by whatever is required to support Sparkgeo's QGIS development priorities.

## Support

Support is currently focused on x86 Linux systems. On other platforms YMMV.

## Branches

QGIS is in the process of migrating from QT5 to QT6 and each platform requires different build steps. This repo's `qt6` branch is intended for 4+ versions (including 3.99 versions in preparation for 4.0) and only supports QT6. The `qt5` branch should work for <=3.44 versions but later versions do not support QT5.

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

A new QGIS build can be forced with a flag if required, bypassing change detection. This deletes any existing build caches and fully re-compiles from source.

```sh
scripts/build-if-necessary.sh --clean-build
```

### Run

Currently running QGIS in a container only supports hosts with X11 (i.e. Linux desktop environments). Quartz on macOS is not guaranteed to work correctly. VNC support may be implemented for non-X11 host environments in future. 

To run QGIS:

```sh
scripts/run.sh
```

This script will build and install QGIS if necessary, based on the same change detection described above, before running the application. 

The [build](#build) script's `--clean-build` flag can also be used here.

```sh
# force clean build
scripts/run.sh --clean-build
```

By default a user profile is persisted between runs. To force a new user profile the `--clean-profile` flag can be used.

```sh
# force new user profile
scripts/run.sh --clean-profile
```

### Test

> [!NOTE]
> This repo currently supports the `ALL_BUT_PROVIDERS` test batch as the only test option, similar to CI. Additional work is required to execute individual tests or different test batches.

To execute all QGIS tests in the default batch:

```sh
# also supports the --clean-build flag
scripts/test.sh
```

To execute individual tests:
```sh
scripts/test.sh --test-identifier test_core_stac
```

This script will build QGIS if necessary, based on the same change detection described above.
