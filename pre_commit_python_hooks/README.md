## Checkatrade Hooks written in Python

`requirements-txt-fixer`: This hook has been taken from the main pre-commit repo [pre-commit-hook-repo](https://github.com/pre-commit/pre-commit-hooks) and has been modified to check if there is a single = between the module and version and if there is a single = it will add another one so you don't get a pip error. e,g  Flask=2.0.2 --> Flask==2.0.2

`tf-module-checker`: This hook goes through all .tf files that have been added into your commit to check if the module source ref is using latest instead of a version, if the module source is using latest it alerts and tells you which module and file is using latest. If there is a case where you need to use latest, you can add  # tf:ignore at the end of the source line e.g `source = "git::git@github.com:cat-home-experts/terraform-modules.git//checkatrade/datadog/monitors?ref=latest" # tf:ignore`


