# CDADance demo superbuild

This repository is a fork of [mc-rtc-superbuild](https://github.com/mc-rtc/mc-rtc-superbuild) configured specifically to build and package the [CDADance](https://github.com/arntanguy/CDADance) demo.

## Building the demo

Simply clone this repository and use one of the provided CMakePresets:

| Preset Name | Description | Transitions |
| :--- | :--- | :--- |
| cdadance-simu-manual | Intended for MuJoCo simulation | manual |
| cdadance-simu-auto | Intended for MuJoCo simulation | automatic |
| cdadance-demo-manual | Intended for HRP4 real robot | manual|
| cdadance-demo-auto | Intended for HRP4 real robot | automatic |

You can use them locally to build the full demo and all needed tools (mujoco, mc-rtc-magnum, xsens plugin, etc)

```
cmake --preset cdadance-<preset>
cmake --build --preset cdadance-preset
```

## Packaging

Continuous integration builds the following release dockerfile based on the above presets:

| Preset Name | Description | Transitions |
| :--- | :--- | :--- |
| ghcr.io/isri-aist/cdadance:simu-manual-standalone-latest | Intended for MuJoCo simulation | manual |
| ghcr.io/isri-aist/cdadance:simu-auto-standalone-latest | Intended for MuJoCo simulation | automatic |
| ghcr.io/isri-aist/cdadance:demo-manual-standalone-latest | Intended for HRP4 real robot | manual|
| ghcr.io/isri-aist/cdadance:demo-auto-standalone-latest | Intended for HRP4 real robot | automatic |

and the corresponding devcontainers:

| Preset Name | Description | Transitions |
| :--- | :--- | :--- |
| ghcr.io/isri-aist/cdadance:simu-manual-devcontainer-latest | Intended for MuJoCo simulation | manual |
| ghcr.io/isri-aist/cdadance:simu-auto-devcontainer-latest | Intended for MuJoCo simulation | automatic |
| ghcr.io/isri-aist/cdadance:demo-manual-devcontainer-latest | Intended for HRP4 real robot | manual|
| ghcr.io/isri-aist/cdadance:demo-auto-devcontainer-latest | Intended for HRP4 real robot | automatic |

See [the cdadance package registry](https://ghcr.io/isri-aist/cdadance) for a full list of releases.
