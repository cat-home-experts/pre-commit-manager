[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://pre-commit.com/)
[![super-linter](https://img.shields.io/badge/super--linter-enabled-brightgreen?logo=github&logoColor=white)](https://github.com/cat-home-experts/pre-commit-manager/actions/workflows/static_analyser.yml)
[![slscan-reports](https://img.shields.io/badge/slscan_artifacts-enabled-brightgreen?logo=adguard&logoColor=white)](https://github.com/cat-home-experts/pre-commit-manager/actions/workflows/security_scanner.yml)
[![slscan-alerts](https://img.shields.io/badge/slscan_alerts-enabled-brightgreen?logo=adguard&logoColor=white)](https://github.com/cat-home-experts/pre-commit-manager/security/code-scanning)

# Pre-Commit Manager

Pre-Commit Manager installs [Pre-Commit](http://pre-commit.com) for you, a Git hooks configuration framework that helps you to push pre-validated code only.

With Pre-Commit, you traditionally need to install the hooks and deploy a configuration each time you create a new repository.
This Pre-Commit Manager does everything for you using the baseline configuration file of your choice. It scans your disk to update the new repositories being added as often as you want.

<details open="open">
<summary>Table of Contents</summary>

- [Pre-Commit Manager](#pre-commit-manager)
  - [Quickstart](#quickstart)
  - [Security Fundamentals](#security-fundamentals)
  - [Installation](#installation)
    - [Requirements](#requirements)
    - [Automatic Installation](#automatic-installation)
    - [Automatic Update of Your Hooks](#automatic-update-of-your-hooks)
    - [Manual Installation](#manual-installation)
    - [Manual Update of Your Hooks](#manual-update-of-your-hooks)
  - [Uninstallation](#uninstallation)
  - [Development](#development)
    - [Repository Description](#repository-description)
    - [Baseline Configuration Update](#baseline-configuration-update)
    - [Hooks in this repo](#hooks-in-this-repo)
      - [dotnet-format](#dotnet-format)
        - [dotnet-format usage](#dotnet-format-usage)
    - [How to Develop your Own Hook?](#how-to-develop-your-own-hook)
  - [Some little tricks](#some-little-tricks)
    - [You want to setup a different pre-commit config file](#you-want-to-setup-a-different-pre-commit-config-file)
    - [You want to run your hooks without calling git](#you-want-to-run-your-hooks-without-calling-git)
    - [You want to push a secret intentionally](#you-want-to-push-a-secret-intentionally)
    - [You would like to bypass a hook](#you-would-like-to-bypass-a-hook)
    - [You would like to bypass all hooks](#you-would-like-to-bypass-all-hooks)
  - [Other Hooks](#other-hooks)

</details>

## Quickstart

Simply run:

```
git clone https://github.com/cat-home-experts/pre-commit-manager.git
cd pre-commit-manager

# Think about $PRECOMMIT_INCLUDE/$PRECOMMIT_EXCLUDE described below to narrow
# down the repositories you want pre-commit to be configured for.

./sources/install-precommit.sh
```

You can use the following environment variables to change the Pre-Commit Manager configuration:

| Variable | Description |
| --- | --- |
| `$PRECOMMIT_UPDATE_FREQUENCY_MINS` | The frequency of scans in minutes (default: 20). Needs to be defined pre-installation, or can be modified post-installation in your crontab. |
| `$PRECOMMIT_BASELINE` | The baseline configuration being injected in your repositories (default: sources/baseline.yaml). |
| `$PRECOMMIT_INCLUDE` | A list of paths **under the $HOME folder** that you want to include in the directory scans (supports wildcard patterns). |
| `$PRECOMMIT_EXCLUDE` | A list of paths **under the $HOME folder** that you want to exclude from the directory scans (supports wildcard patterns). |
| `$PRECOMMIT_CUSTOM` | The pre-commit configuration file name you want to use for all your repositories. You can use this environment variable to create your own pre-commit config while the team uses the default one which would be git versioned. And then put your personal config in .gitignore |

`$PRECOMMIT_INCLUDE` take precedence over `$PRECOMMIT_EXCLUDE`, meaning you can overlap as below:

```bash
# Assuming you have only git repos under GitHub/hashicorp/ and GitHub/organization/, + a single repo GitHub/my-repo
export PRECOMMIT_INCLUDE="*organization/pre-commit-manager,*hashicorp/terraform"
export PRECOMMIT_EXCLUDE="*hashicorp/*,*organization*,$HOME/Documents/GitHub/my-repo"
```

Pre-Commit Manager will scan this list to deploy the hooks and the baseline configuration:

```
$HOME/Documents/GitHub/hashicorp/terraform
$HOME/Documents/GitHub/organization/pre-commit-manager
```

## Security Fundamentals

The Pre-Commit usage approach relies on systematic ways of:

- preventing non-approved code from entering the code base,
- detecting if such preventions are explicitly bypassed.

This way, you create a separation of concern: accepting that there may currently be non-compliant code in your large repositories, but preventing this issue from getting any larger.

The Pre-Commit Manager baseline configuration can be extended post-deployment to any kind of control you would like to set up, using any Pre-Commit hook of your choice or even developping your own ones in any language of your choice [see supported languages](https://pre-commit.com/#supported-languages).

Pre-Commit can also be run in your CI/CD pipeline. The same hooks you use locally can be run server-side, see [pre-commit run](https://pre-commit.com/#pre-commit-run).

## Installation

### Requirements

You need to install the underlying binary of your hook yourself.
We recommend using [asdf](http://asdf-vm.com/guide/getting-started.html#_3-install-asdf) if your binary is deployable with it.

### Automatic Installation

See [Quickstart](#quickstart)

Grab yourself a :coffee:
> Depending on the number of repositories being present on your computer under your HOME directory, it could take something like 3 to 10 mins.

To get more detail about Pre-Commit, please refer to the [Pre-Commit Project website](https://pre-commit.com/#intro).

### Automatic Update of Your Hooks

Pre-Commit Manager does not update the hooks by itself and respect the repository versioned configuration. Once it deploys the baseline config, it won't overwrite and update the hooks.
If you want to update all your hooks revisions in a specific repository, run the below under its root folder:

```
pre-commit autoupdate
pre-commit clean
```

### Manual Installation

From the root folder of your repository:

- Create __`.pre-commit-config.yaml`__. Use any example you have under [sources/](sources/) to configure your hooks following that [documentation](https://pre-commit.com/#adding-pre-commit-plugins-to-your-project). You can find other hooks [here](https://pre-commit.com/hooks.html).
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
-  rev: v1.0.0
+  rev: 1.1.3
   hooks:
   - id: detect-unencrypted-ansible-vault
     exclude: '^$'
```

And run:

```
pre-commit clean
# ▽▽ if needed
#pre-commit install
#pre-commit install --hook-type pre-push
#pre-commit install --hook-type commit-msg
```

## Uninstallation

You'll be guided through the uninstallation process using this [script](sources/uninstall-precommit.sh).

```
git clone https://github.com/cat-home-experts/pre-commit-manager.git
cd pre-commit-manager
./sources/uninstall-precommit.sh
# or
./sources/uninstall-precommit.sh -q  # non-interactive mode
```

## Development

### Repository Description

```
.
├── .gitignore
├── .pre-commit-config.yaml.yaml            => Hooks configured for this repo
├── .pre-commit-hooks.yaml                  => Index of the Pre-Commit hooks offered by Pre-Commit Manager
├── pre-commit-hooks                        => Hooks offered by Pre-Commit Manager
│   ├── detect-unsigned-commit.sh           => Hook for unsigned commits detection
│   ├── detect-unencrypted-ansible-vault.sh => Hook for unencrypted Ansible vaults detection
│   ├── terraform-fmt.sh                    => Hook running 'terraform fmt'
│   ├── terraform-validate.sh               => Hook running 'terraform validate' & 'tflint --enable-rule=terraform_unused_declarations
│   ├── terraform-docs.sh                   => Hook running 'terraform-docs' to initialize or update your README.md
│   ├── terragrunt-fmt.sh                   => Hook running 'terragrunt hclfmt'
│   └── terragrunt-validate.sh              => Hook running 'terragrunt validate' & 'terragrunt validate-inputs'
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

### Baseline Configuration Update

In case of any update on the baseline configuration [sources/baseline.yaml](sources/baseline.yaml), you would need to **create a new GitHub release**. Simply create a feature branch and open a Pull Request. A CI/CD pipeline will manage the rest for you after approval.

### Hooks in this repo

You are free to consume any hook in this repo by including a call to them (by ID and repo URL) in your repo's `.pre-commit-config.yaml`. Examples for each hook can be found below

#### dotnet-format

This hook will simply run `dotnet format` using your installed dotnet SDK with a number of hardcoded command line flags. The hook will:

- Run using the `.editorconfig` in your repo
- Only operate on modified or added files of type .cs, .csproj or .sln
- Not run an implicit restore
- Automatically make changes to resolve linting issues

If changes need to be made the hook will fail and unstage the files, so you'll need to `git add` them again.

##### dotnet-format usage

Add the following to your .pre-commit-config.yaml to run dotnet format on every commit:

```yml
  - repo: https://github.com/cat-home-experts/pre-commit-manager
    rev: 1.9.0
    hooks:
      - id: dotnet-format
        stages: [commit]
        types_or: ["c#", "vb", "sln", "csproj"]
```

### How to Develop your Own Hook?

You're more than welcome to extend the set of hooks offered by Pre-Commit Manager.

1. Check the list of [supported languages](https://pre-commit.com/#supported-languages).
2. Develop your hook and push it to https://github.com/cat-home-experts/pre-commit-manager under [pre-commit-hooks/](pre-commit-hooks/).
3. Update the hook index [.pre-commit-hooks.yaml](.pre-commit-hooks.yaml). This [documentation](https://pre-commit.com/#creating-new-hooks) will provide you the different index settings available.
4. Update the hook baseline configuration [sources/baseline.yaml](sources/baseline.yaml) or simply add a template under [sources/collection/](sources/collection/). You will need to provide a unique (within the hook index) hook id and the release version number (next release which might be updated during the approval process). This [documentation](https://pre-commit.com/#adding-pre-commit-plugins-to-your-project) will provide you the different hook configuration settings available.
5. Create a new branch and open a Pull Request.

## Some little tricks

### You want to setup a different pre-commit config file

By default Pre-Commit Manager will deploy the baseline config as `.pre-commit-config.yaml` under your repo root directory, unless you specify a different file name using the environment variable `$PRECOMMIT_CUSTOM` prior to run the installation script (see [Quickstart](#quickstart)).

But you can also, per repo basis, run the following command under your repo root directory: `pre-commit install --config my-personal-config.yaml`.

### You want to run your hooks without calling git

Run all the hooks on your repository: `pre-commit run --all-files`.

Run a specific hook from your configuration: `pre-commit run <hook id>`.

### You want to push a secret intentionally

If you're using the https://github.com/Yelp/detect-secrets `detect-secrets` hook, you could insert a pragma instruction at the end of a line containing a secret which triggers the Yelp hook. This directive would chirurgically ignore the secret during your push/commit.

`# pragma: allowlist secret` is the native Yelp instruction. But the Pre-commit Manager baseline config enables the adoption of `# scan:ignore` too.

See the example below:

```
API_KEY = "actually-not-a-secret" # scan:ignore
print('hello world')
```

### You would like to bypass a hook

Run: `SKIP=<your hook id in .pre-commit-config.yaml> git push`.

For example this command ignores 2 hooks: `SKIP="check-merge-conflict,mixed-line-ending" git push`.

If you want to use a permanent skip, just configure the SKIP variable as an environment one using one of your dotfiles.

### You would like to bypass all hooks

Run: `git push --no-verify`.

## Other Hooks

You will find a source of inspiration for additional hooks [here](https://pre-commit.com/hooks.html) :green_book:.

Eventually check out these ones:

- [search-and-replace](https://github.com/mattlqx/pre-commit-search-and-replace)
- [swagger validation](https://github.com/APIDevTools/swagger-cli)

:bulb: :question: :boom:
If you want to share an issue or question :point_right: [create a GitHub issue](https://github.com/cat-home-experts/pre-commit-manager/issues)
