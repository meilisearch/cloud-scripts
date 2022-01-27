# Contributing <!-- omit in TOC -->

First of all, thank you for contributing to Meilisearch! The goal of this document is to provide everything you need to know in order to contribute to Meilisearch and its different integrations.

- [Assumptions](#assumptions)
- [How to Contribute](#how-to-contribute)
- [Git Guidelines](#git-guidelines)
- [Release Process (for internal team only)](#release-process-for-internal-team-only)

## Assumptions

1. **You're familiar with [GitHub](https://github.com) and the [Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests)(PR) workflow.**
2. **You've read the Meilisearch [documentation](https://docs.meilisearch.com) and the [README](/README.md).**
3. **You know about the [Meilisearch community](https://docs.meilisearch.com/resources/contact.html). Please use this for help.**

## How to Contribute

1. Make sure that the contribution you want to make is explained or detailed in a GitHub issue! Find an [existing issue](https://github.com/meilisearch/cloud-scripts/issues/) or [open a new one](https://github.com/meilisearch/cloud-scripts/issues/new).
2. Once done, [fork the cloud-scripts repository](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) in your own GitHub account. Ask a maintainer if you want your issue to be checked before making a PR.
3. [Create a new Git branch](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-and-deleting-branches-within-your-repository).
4. Make the changes on your branch.
5. [Submit the branch as a PR](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork) pointing to the `main` branch of the main cloud-scripts repository. A maintainer should comment and/or review your Pull Request within a few days. Although depending on the circumstances, it may take longer.<br>
 We do not enforce a naming convention for the PRs, but **please use something descriptive of your changes**, having in mind that the title of your PR will be automatically added to the next [release changelog](https://github.com/meilisearch/cloud-scripts/releases/).

## Git Guidelines

### Git Branches <!-- omit in TOC -->

All changes must be made in a branch and submitted as PR.
We do not enforce any branch naming style, but please use something descriptive of your changes.

### Git Commits <!-- omit in TOC -->

As minimal requirements, your commit message should:
- be capitalized
- not finish by a dot or any other punctuation character (!,?)
- start with a verb so that we can read your commit message this way: "This commit will ...", where "..." is the commit message.
  e.g.: "Fix the home page button" or "Add more tests for create_index method"

We don't follow any other convention, but if you want to use one, we recommend [this one](https://chris.beams.io/posts/git-commit/).

### GitHub Pull Requests <!-- omit in TOC -->

Some notes on GitHub PRs:

- [Convert your PR as a draft](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/changing-the-stage-of-a-pull-request) if your changes are a work in progress: no one will review it until you pass your PR as ready for review.<br>
  The draft PR can be very useful if you want to show that you are working on something and make your work visible.
- The branch related to the PR must be **up-to-date with `main`** before merging. If it's not, you have to rebase your branch. Check out this [quick tutorial](https://gist.github.com/curquiza/5f7ce615f85331f083cd467fc4e19398) to successfully apply the rebase from a forked repository.
- All PRs must be reviewed and approved by at least one maintainer.
- The PR title should be accurate and descriptive of the changes.

## Release Process (for internal team only)

The release tags of this package follow exactly the Meilisearch versions.<br>
It means that, for example, the `v0.17.0` tag in this repository corresponds to the scripts for deploying Meilisearch `v0.17.0`.

This repository currently does not provide any automated way to test and release the cloud scripts.<br>
**Please, follow carefully the steps in the next sections before any release.**

### Test before Releasing <!-- omit in TOC -->

1. In [`scripts/cloud-config.yaml`](scripts/cloud-config.yaml), update the Meilisearch version used in the `wget` command of the `runcmd` section. Use the version number that you want to release, in the format: `vX.X.X`. If you want to test with a Meilisearch RC, replace it by the right RC version tag (`vX.X.XrcX`).

2. Commit your changes on a new branch.

3. Create a git tag on the last commit of your recently created branch:

```bash
git tag vX.X.X
git push origin vX.X.X
```

3. Test the script: changes in this repository can not be tested by themselves. Other repositories, as [meilisearch-digitalocean](https://github.com/meilisearch/meilisearch-digitalocean/) or [meilisearch-aws](https://github.com/meilisearch/meilisearch-aws/) use this scripts to configure instances on the respective cloud provider. In order to test any changes in this repository, you need to run the tests of those repositories. For example:

 - [Test meilisearch-digitalocean](https://github.com/meilisearch/meilisearch-digitalocean/blob/main/CONTRIBUTING.md#release-process-for-internal-team-only)
 - [Test meilisearch-aws](https://github.com/meilisearch/meilisearch-aws/blob/main/CONTRIBUTING.md#release-process-for-internal-team-only)

 4. If you are testing a Release Candidate of Meilisearch (`vX.X.XrcX`) version of Meilisearch, please delete the tag after testing.

 ```bash
 $ git tag -d vX.X.XrcX
 $ git push --delete origin vX.X.XrcX
 ```

 ### Release <!-- omit in TOC -->

⚠️ This process shouldn't be followed when testing a `RC` version of Meilisearch.

 1. Create a PR pointing to `main` branch and merge it.

 2. Move the tag to the last commit of the `main` branch.

 ```bash
 $ git tag -d vX.X.X
 $ git push --delete origin vX.X.X
 $ git checkout main
 $ git pull origin main
 $ git tag vX.X.X
 $ git push origin vX.X.X
```

<hr>

Thank you again for reading this through, we can not wait to begin to work with you if you made your way through this contributing guide ❤️
