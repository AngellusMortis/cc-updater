# ComputerCraft Updater

Utility to update a CC: Tweaked computer automatically using a Github repo.

I am a developer. I would rather do development in my VS Code with my syntax highlighting and such. And I would prefer to
have everything version controlled (git). This is the latest iteration of my method of doing it: use Github + Github
Actions to generate a manifest that CC: Tweaked can use to automatically download and update files on your computer.

## Install

TODO

## Add Extra Repos

TODO

## How it Works

Whenever a commit is made to the default branch of this repo, it will automatically run the
[manifest.yml workflow](https://github.com/AngellusMortis/cc-updater/blob/master/.github/workflows/manifest.yml). This
workflow will find every `.lua` file and generate a new `manifest.json` file and commit it back to the repo.

Then `ghuupdate.lua` on the computer will use the `gha.coreRepo` and `gha.extraRepos` settings to pull the `manifest.json`
for each configured repo and compare that manifest with the manifest on disk and update any files that have changed.
