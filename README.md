# Configuration as Data - A step-by-step introduction to the toolchain

## Introduction
This repository hosts the code and configuration examples demoing the Configuration as Data (CaD) toolchain of [kpt](https://kpt.dev/book/), [porch](https://kpt.dev/book/08-package-orchestration/) and [config-synch](https://kpt.dev/gitops/configsync/).  

![Configuration as Data Toolchain](/images/nephio_cad_toolchain.png)   

The instructions in the READMEs in this directory and its subdirectories describe how to run the demos in a Docker container on your laptop.  

However, it is straight forward to run the same on a [Google Cloud Workstation](https://cloud.google.com/workstations).
If you choose to do so you can follow the instructions provided in the [online documentation](https://cloud.google.com/workstations/docs/create-cluster) to run the container image on Cloud Workstations.  

Each demo in the subdirectories runs in a [Cloud Workstations Docker container](https://cloud.google.com/workstations/docs/customize-container-images) with [Code OSS](https://cloud.google.com/workstations/docs/preconfigured-base-images#list_of_preconfigured_base_images) installed.  
This allows you to either run the demo on your laptop or on a [Google Cloud Workstation](https://cloud.google.com/workstations).

The repository contains the following subdirectories which contain examples of how to use CaD tooling with progessive sophistication.
* [Day 1](/Day1/README.md) - Provision a simple app using Config Sync and Kubernetes Manifests
* [Day 2](/Day2/README.md) - Provision a simple app using Config Sync and kpt
* [Day 3](/Day3/README.md) - Provision a simple app using Config Sync, kpt and porch 
* [Day 4](/Day4/README.md) - Provision a simple app to a set of Kubernetes clusters using Config Sync, kpt and porch
* [Day 5](/Day4/README.md) - Run the lot as managed services (where available) on Google Cloud

## Instructions
After cloning this repo you can follow the instructions in the READMEs contained in the subdirectories.

The first step in each demo is to run a Docker container that contains the demo environment.  
Once you started the container (command found in the README in each subdirectory) you can point your browser to [http://localhost:8080/](http://localhost:8080/).  
This will give you access to the Code OSS IDE.  

![Code OSS environment in your browser](/images/cloud_workstations.png)

From there you can access the menu to start a new terminal window.

![Code OSS environment in your browser](/images/new_terminal_window.png)

This will give you a command prompt from which you can execute the commands for each of the demos.

![Code OSS environment in your browser](/images/terminal_window.png)

Let's get started with the [first demo](/Day0/README.md)!

```
# Copyright 2023 Google LLC.
# This software is provided as-is, without warranty or representation for any use or purpose.
# Your use of it is subject to your agreement with Google.
```
