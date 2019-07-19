# Jenkins X Versions


This repository  contains the consistent set of versions of packages and helm charts for use with [Jenkins X](https://jenkins-x.io/) and its associated Apps to provide a [stable version stream](https://jenkins-x.io/architecture/version-stream/).

* [charts](charts) contains the versions of [helm](https://www.helm.sh/) charts
* [packages](packages) contains the versions of CLI tools like `jx`, `helm` etc


## Layout

Each folder contains a list of YAML files for each package or chart name which contains its `version` and its `gitUrl`, `url` to the GitHub project storing its source code.

## Managing versions

By default this git repository is used by the [jx](https://github.com/jenkins-x/jx) binary whenever it needs to install a helm a chart so that rather than using the latest released chart, we can keep the versions locked down to known good versions.

Then as charts get released we can generate Pull Requests against this repository which will then trigger our [BDD tests](https://github.com/jenkins-x/bdd-jx) via [jx step bdd](https://jenkins-x.io/commands/jx_step_bdd/) and verify the new chart version works.

## BDD Test Pipelines

You can browse all of the separate BDD tests we run on different kinds of cluster and installation in the [jx/bdd](jx/bdd) folder.
