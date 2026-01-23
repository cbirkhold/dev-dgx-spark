# Developer Tools for NVIDIA DGX Spark

## Motivation

A template for Isaac Sim/Isaac Lab projects on NVIDIA DGX Spark that builds the relevant libraries from source and creates a virtual environment that includes the Isaac Sim/Isaac Lab packages as well as the relevant environment configuration.

The Python interpreter can then be invoked directly in the activated venv without further manual configuration. Project-specific packages are installed in the venv rather than the Isaac Sim bundled Python environment.

```bash
(dev-dgx-spark) chris@spark:~/dev-dgx-spark$ python experiment.py
```

## Install

The install script:

- Checks pre-conditions
- Configures the system
  - fs.inotify limits
- Installs system dependencies
  - alternatives system
- Initializes the repository
- Builds vendor SDKs
  - Build Isaac Sim
  - Install Isaac Lab in Isaac Sim setup
  - Log Python environment
- Creates a Python venv

**NOTE:** There are a number of files that are intended only for development on this template rather than for inclusion in a concrete project. Use `git archive` to create a template for a concrete project.

```bash
./install/install.sh
```

## Run Scripts

```bash
# Run Python scripts in the proper environment
source activate
./run.sh [SCRIPT]
deactivate
```

## Test

```bash
source activate
./test.sh
deactivate
```

## Licenses

This repository is available under the MIT License.

Submodules are subject to their respective licenses:

- NVIDIA Isaac Lab: see sdks/vendor/isaaclab/LICENSE, sdks/vendor/isaaclab/LICENSE-mimic
- NVIDIA Isaac Sim: see sdks/vendor/isaacsim/LICENSE

Python modules are subject to their respective licenses (`uv run pip-licenses`).
