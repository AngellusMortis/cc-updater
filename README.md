# ComputerCraft Updater

Utility to update a CC: Tweaked computer automatically using a Github repo.

I am a developer. I would rather do development in my VS Code with my syntax highlighting and such. And I would prefer to have everything version controlled (git). This is the latest iteration of my method of doing it: use Github + Github Actions to generate a manifest that CC: Tweaked can use to automatically download and update files on your computer.

## Install

Run the following command in your computer:

```bash
gist run 4e2cf0a2ded3df7ee60127a44d17d655
```

You can view the [source of the gist](https://gist.github.com/AngellusMortis/4e2cf0a2ded3df7ee60127a44d17d655) before installing

## Add Extra Repos

Go to the [template repo](https://github.com/AngellusMortis/cc-updater-template) and click "Use this template" and create a public repository (private repos are not supported). Add your files the `src` directory and commit/push them. Github Actions will automatically generate a `src/manifest.json` whenever you commit to the default branch.

Then you can run `ghuconf add extraRepos {username}/{repo}:/src` inside of your computer followed by `ghuupdate` and your repo will automatically be downloaded. You can optionally add `@{ref}` for target any specific ref or change `/src` to any other specific path. Example: `AngellusMortis/cc-updater@v2:/optional` would use the repo `AngellusMortis/cc-updater` with the ref `v2` and use `/optional/manifest.json` to donwload files.

## How it Works

Whenever a commit is made to the default branch of this repo, it will automatically run the [manifest.yml workflow](https://github.com/AngellusMortis/cc-updater/blob/master/.github/workflows/manifest.yml). This workflow will find every `.lua` file and generate a new `src/manifest.json` file and commit it back to the repo.

Then `ghuupdate.lua` on the computer will use the `ghu.coreRepo` and `ghu.extraRepos` settings to pull the `src/manifest.json` for each configured repo and compare that manifest with the manifest on disk and update any files that have changed.

The `ghu.coreRepo` will automatically be downloaded to `/ghu/core` and each `ghu.extraRepos` will be downloaded to `/ghu/{username}/{repo}`. These paths will also automatically be added to your shell path as well following the same rules as the normal CraftOS paths (`programs/` will be added for all computers, `programs/advanced/` will be added for Advanced Computers, etc.)

## Note About Caching

CraftOS seems heavily cache files http calls. As a result, it may take up to 5 minutes for new files to be detected by `ghuupdate.lua`. If you know any way to improve this, please make an issue or PR and let's talk about it!
