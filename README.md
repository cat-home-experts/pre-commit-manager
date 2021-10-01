[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://pre-commit.com/)
[![super-linter](https://img.shields.io/badge/super--linter-enabled-brightgreen?logo=github&logoColor=white)](https://github.com/cat-home-experts/pre-commit-manager/actions/workflows/static_analyser.yml)
[![slscan-reports](https://img.shields.io/badge/slscan_artifacts-enabled-brightgreen?logo=adguard&logoColor=white)](https://github.com/cat-home-experts/pre-commit-manager/actions/workflows/security_scanner.yml)
[![slscan-alerts](https://img.shields.io/badge/slscan_alerts-enabled-brightgreen?logo=adguard&logoColor=white)](https://github.com/cat-home-experts/pre-commit-manager/security/code-scanning)

# Pre-Commit Manager

Pre-Commit Manager installs for you [Pre-Commit](http://pre-commit.com), a Git hooks configuration framework that helps you to push pre-validated code only.

With Pre-Commit, you traditionally need to install the hooks and deploy a configuration each time you create a new repository.
This Pre-Commit Manager does everything for you using the baseline configuration file of your choice and scans your disk to update the new repositories being added as often as you want.

You can use the following environment variables to change its configuration:

| Variable | Description |
| --- | --- |
| `$PRECOMMIT_UPDATE_FREQUENCY_MINS` | The frequency of scans in minutes (default: 20). Needs to be defined pre-installation, or can be modified post-installation in your crontab. |
| `$PRECOMMIT_BASELINE` | The baseline configuration being injected in your repositories (default: sources/baseline.yaml) |
| `$PRECOMMIT_INCLUDE` | a list of paths **under the $HOME folder** that you want to include in the directory scans (supports wildcard patterns) |
| `$PRECOMMIT_EXCLUDE` | a list of paths **under the $HOME folder** that you want to exclude from the directory scans (supports wildcard patterns) |

`$PRECOMMIT_INCLUDE` take precedence over `$PRECOMMIT_EXCLUDE`, meaning you can overlap as below:

```bash
# Assuming you have only git repos under GitHub/hashicorp/ and GitHub/organization/, + a single repo GitHub/my-repo
export PRECOMMIT_INCLUDE="*organization/pre-commit-manager,*hashicorp/terraform"
export PRECOMMIT_EXCLUDE="*hashicorp/*,*organization*,$HOME/Documents/GitHub/my-repo"
```

Pre-Commit Manager will scan this list to deploy the hooks and the baseline config configured:

```
$HOME/Documents/GitHub/hashicorp/terraform
$HOME/Documents/GitHub/organization/pre-commit-manager
```

## Contents

- [Pre-Commit Manager](#pre-commit-manager)
  - [Contents](#contents)
  - [Quickstart](#quickstart)
  - [Security Fundamentals](#security-fundamentals)
  - [Repository Description](#repository-description)
  - [Installation](#installation)
    - [Requirements](#requirements)
    - [Automatic Installation](#automatic-installation)
    - [Automatic Update of Your Hooks](#automatic-update-of-your-hooks)
    - [Manual Installation](#manual-installation)
    - [Manual Update of Your Hooks](#manual-update-of-your-hooks)
  - [Uninstallation](#uninstallation)
  - [Maintenance](#maintenance)
    - [Change on the existing configuration](#change-on-the-existing-configuration)
    - [You want to develop your own hook](#you-want-to-develop-your-own-hook)
  - [Some little tricks](#some-little-tricks)
    - [You want to run your hooks](#you-want-to-run-your-hooks)
    - [You want to push a secret intentionally](#you-want-to-push-a-secret-intentionally)
    - [You would like to bypass a hook for a specific push](#you-would-like-to-bypass-a-hook-for-a-specific-push)
    - [You would like to bypass all hooks for your push](#you-would-like-to-bypass-all-hooks-for-your-push)
  - [Other Hooks](#other-hooks)

## Quickstart

:metal: Just run:

```
git clone https://github.com/cat-home-experts/pre-commit-manager.git
cd pre-commit-manager
./sources/install-precommit.sh
```

## Security Fundamentals

The Pre-Commit usage approach relies on systematic ways of:

- preventing non-approved code from entering the code base,
- detecting if such preventions are explicitly bypassed.

This way, you create a separation of concern: accepting that there may currently be non-compliant code in your large repositories, but preventing this issue from getting any larger.

The Manager baseline Pre-Commit configuration can be extended to any kind of control you would like to set up, granularly per repo, and in any language of your choice as Pre-Commit is a multi-language hooks manager.

Pre-Commit can also be run in your CI/CD pipeline. The same hooks you use locally can be run server-side, see [pre-commit run](https://pre-commit.com/#pre-commit-run).

## Repository Description

```
.
├── .gitignore
├── .pre-commit-config.yaml.yaml            => Hooks configured for this repo
├── .pre-commit-hooks.yaml                  => Index of the Pre-Commit hooks offered by Pre-Commit Manager
├── pre-commit-hooks                        => Hooks offered by Pre-Commit Manager
│   ├── detect-unsigned-commit.sh           => Hook for unsigned commits detection
│   ├── detect-unencrypted-ansible-vault.sh => Hook for unencrypted Ansible vaults detection
│   ├── terraform-fmt.sh                    => Hook running 'terraform fmt'
│   ├── terraform-validate.sh               => Hook running 'terraform validate'
│   ├── terraform-docs.sh                   => Hook running 'terraform-docs' to initialize or update your README.md
│   ├── terragrunt-fmt.sh                   => Hook running 'terragrunt hclfmt'
│   └── terragrunt-validate.sh              => Hook running 'terragrunt validate-inputs' and 'terragrunt validate'
├── sources                                 => Manager sources
│   ├── collection                          => A list of configuration examples that can be used as templates
│   │   ├── aws.yaml
│   │   ├── docker.yaml
│   │   ├── markdown.yaml
│   │   ├── shell.yaml
│   │   └── terraform.yaml
│   ├── baseline.yaml                       => Pre-Commit configuration being deployed automatically in its latest release in your repositories
│   ├── install-precommit.sh                => Installtion script of Pre-Commit Manager
│   └── uninstall-precommit.sh              => Uninstalltion script of Pre-Commit Manager
└── README.md
```

## Installation

:mag_right:

### Requirements

Some hooks might require to install its related binary like for example https://github.com/awslabs/git-secrets which requires to install `git-secrets` or https://github.com/bridgecrewio/checkov depending on `checkov`.

### Automatic Installation

See [Quickstart](#quickstart)

Grab yourself a :coffee:
> Depending on the number of repositories being present on your computer under your HOME directory, it could take something like 3 to 10 mins.

To get more detail about Pre-Commit, please refer to the [Pre-Commit Project website](https://pre-commit.com/#intro).

### Automatic Update of Your Hooks

Pre-Commit Manager does not update the hooks by itself and respect the repo versioned configuration.
If you want to update all your hooks revisions in a specific repo, run under its root level:

```
pre-commit autoupdate
pre-commit clean
```

### Manual Installation

:muscle:

From the root folder of your repository (the one you want to add Git hooks to):

- deploy a yaml file and name it __`.pre-commit-config.yaml`__. Use any examples you have in `sources/*.yaml` to configure your hooks following that [documentation](https://pre-commit.com/#adding-pre-commit-plugins-to-your-project).
You can find other hooks [here](https://pre-commit.com/hooks.html).
- run:

```
pre-commit install
pre-commit install --hook-type pre-push
pre-commit install --hook-type commit-msg
pre-commit autoupdate
```

### Manual Update of Your Hooks

Update your hooks configuration file as below for instance:

__`.pre-commit-config.yaml`__:

```diff
 exclude: '^$'
 default_stages: [push]
 repos:
 - repo: https://github.com/cat-home-experts/pre-commit-manager
-  rev: v1.0
+  rev: v1.1
   hooks:
   - id: detect-unencrypted-ansible-vault
     exclude: '^$'
```

And run:

```
pre-commit clean
# ▽▽ if required
#pre-commit install
#pre-commit install --hook-type pre-push
#pre-commit install --hook-type commit-msg
```

## Uninstallation

You will be guided by the uninstallation script `sources/uninstall-precommit.sh`.

```
git clone https://github.com/cat-home-experts/pre-commit-manager.git
cd pre-commit-manager
./sources/uninstall-precommit.sh
# or
./sources/uninstall-precommit.sh -q # to get rid off everything in one shot
```

## Maintenance

### Change on the existing configuration

In case of any update on the baseline configuration `sources/.pre-commit-config.yaml`, you will need to **create a new tag** or new GitHub release from the Github [interface](https://github.com/cat-home-experts/pre-commit-manager/releases) and publish it.

### You want to develop your own hook

:raised_hands:

1. Check the list of [supported languages](https://pre-commit.com/#supported-languages).
2. Develop your hook and push it to https://github.com/cat-home-experts/pre-commit-manager at the root level.
3. Update the hook index `.pre-commit-hooks.yaml`. This [documentation](https://pre-commit.com/#creating-new-hooks) will provide you the different settings available.
4. Update the hooks base configuration `sources/.pre-commit-config.yaml`, adding your hook id, and updating its release version number. This [documentation](https://pre-commit.com/#adding-pre-commit-plugins-to-your-project) will provide you the different settings available.
5. Create a new release on this repo matching the release you specified at the previous step.

## Some little tricks

### You want to run your hooks

Run all hooks from your config file: `pre-commit run --all-files`

Run a specific hook from your config: `pre-commit run <hook id>`

### You want to push a secret intentionally

If you're using the https://github.com/Yelp/detect-secrets `detect-secrets` hook, you could insert the pragma instruction `pragma: allowlist secret`, which is a directive enabling chirurgically a secret to be ignored during your push.

See the example below:

```
API_KEY = "actually-not-a-secret"  # pragma: allowlist secret
print('hello world')
```

### You would like to bypass a hook for a specific push

Run: `SKIP=<your hook id in .pre-commit-config.yaml> git push`

For example this command ignores 2 hooks: `SKIP=check-merge-conflict,mixed-line-ending git push`

### You would like to bypass all hooks for your push

Run: `git push --no-verify`

## Other Hooks

You will find a source of inspiration for additional hooks [here](https://pre-commit.com/hooks.html) :green_book:.

Eventually check out these ones:

- [search-and-replace](https://github.com/mattlqx/pre-commit-search-and-replace)
- [swagger validation](https://github.com/APIDevTools/swagger-cli)

:bulb: :question: :boom:
If you want to share an issue or question :point_right: [create a GitHub issue](https://github.com/cat-home-experts/pre-commit-manager/issues)
