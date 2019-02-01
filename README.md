# Jenkins X Versions

This repository  contains the consistent set of versions of packages and helm charts for use with [Jenkins X](https://jenkins-x.io/) and its associated Apps.

* [charts](charts) contains the versions of [helm](https://www.helm.sh/) charts
* [packages](packages) contains the versions of CLI tools like `jx`, `helm` etc


## Layout

Each folder contains a list of YAML files for each package or chart name which contains its `version` and its `url` to the GitHub project storing its source code.

