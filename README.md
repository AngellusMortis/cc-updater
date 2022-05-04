# ComputerCraft Updater

Lightweight dependency manager for CC: Tweaked.

The goal is to make an easier way to distribute code to multiple computers quickly and consistently. This is not designed to be a full-blown package manager (maybe someday), but it does allow you to update modules from Github as well as automatically pull dependencies for them (no conflict resolution).

## Install

Run the following command in your computer:

```bash
wget run https://raw.githubusercontent.com/AngellusMortis/cc-updater/master/install.lua
```

Since ComputerCraft computers have size limits for computers, by default, all Lua files that are downloaded are minified. If you would like to change this behavior global for all files, you can run

```bash
ghuconf set minified false
```

## Adding Repos

You can add a repo for your computer using the `ghuconf` command. Format for adding new repos is `ghuconf add extraRepos {username}/{repo}:/src`.

For example, if you want to add my [work in progress rendering library](https://github.com/AngellusMortis/am-cc/tree/master/render):

```bash
ghuconf add extraRepos AngellusMortis/am-cc:/render default
```

You can optionally add `@{ref}` after the repo to pull a specific git ref (branch, tag or sha).

You can find Github repos using `cc-updater` at by [searching Github](https://github.com/search?q=topic%3Acc-updater-package)

The last parameter is how you want to handle minification. `default` uses the global `ghu.minified` setting, `true` forces files to be minified and `false` forces them to not be minified.

## Making New Repos

Go to the [template repo](https://github.com/AngellusMortis/cc-updater-template) and click "Use this template" and create a public repository (private repos are not supported). After you create your repo, go to "Settings -> Actions -> General" and change "Workflow Permissions" to "Read and write permissions"

Add your files the `src` directory and commit/push them. Github Actions will automatically generate a `src/manifest.json` whenever you commit to the default branch. After the `manifest.json` is made, you can use `ghuconf` to add the repo to your computer.

The folder structure largely mimics the folder structure from the CraftOS `rom` folder:

* `/help`: `.txt` files added to the `/help` folder will be automatically added as help modules
* `/programs`: `.lua` files added to the `/programs` folder will automatically be available in your shell path to run. Matches the same folder structure as CraftOS `rom` folder (`/programs/turtle` will be added if it is a turtle, etc.)
* `/autorun`: Since cc-updater adds a `startup.lua` to your computer, you can add `.lua` files to `/autorun` that will automatically be ran to extend `startup.lua` and automatically start programs. This functionallity can be disabled with `ghuconf set autoRun false`.
* `/apis`: `.lua` files added to the `/apis` folder will be available to import as Lua modules. Since there is no persistent way to add module paths, you will have to add the following to a Lua file to load them by their relative name:

    ```lua
        local ghu = require(settings.get("ghu.base") .. "core/apis/ghu")
        ghu.initModulePaths()

        -- example to load UI library from WIP rendering lib above (AngellusMortis/am-cc:/render):
        local ui = require("uiLib")
    ```

* `/deps.json`: A JSON array of other Github repos that this one depends on. Will automatically be injected into the `manifest.json` when it is generated.

## Versioning

There are a couple of Github Actions workflows to help you manage Git tags and versions in the template repo. It is designed to follow a [2 digit semver](https://semver.org/). In other words, you can run the "Bump Minor" workflow to increase the minor version, indicating that the changes are safe and there are no breaking API changes and anyone using that major version tag will automatically get the update next time they run `ghuupdate`. Then there is the "Bump Major" workflow to cut a new major version which people will _not_ automatically get unless they are using `master` as a ref.

The initial version of the template repo is 0.1.

## Provided Programs

### ghuupdate

This is basically the secret sauce. `ghuupdate` will use the settings `ghu.coreRepo` and `ghu.extraRepos` to pull `manifest.json` files from those Github repos and then update the files on disk. `ghuupdate` is automatically ran in the `startup.lua`. To disable the auto update, you can run `ghuconf set autoUpdate false`

### ghureload

Simple script to clear shell paths and then re-run the default `startup.lua` to "simulate" a reboot. Really useful if you cannot easily reboot the computer (background program running or you are using something like the awesome [ComputerCraft VS Code extension](https://marketplace.visualstudio.com/items?itemName=jackmacwindows.vscode-computercraft).

### ghuconf

Helper program to manage cc-updater settings. You can do the same thing with `set` and `get` programs, but this one is just a bit nicer since it is specific for `ghu.` settings.

#### All Settings

* `base` - the root folder for cc-updater. Changing the value is not supported/tested
* `autoUpdate` - Automatically run `ghuupdate` in `startup.lua`. Defaults to `true`
* `autoRun` - Automatically run any `.lua` files in `/autoruns` for each cc-updater repo. Defaults to `true`
* `coreRepo` - The Github ref for the `cc-updater` repo. Changing the value is not supported/tested
* `extraRepos` - A list of subscribed Github repos
* `minified` - Downloads files minified or not. Defaults to `true`

#### Examples

* `ghuconf list` will list all `ghu.` settings
* `ghuconf get extraRepo` will list all subscribed Github repos
* `ghuconf help autoUpdate` will print out the help for the `ghu.autoUpdate` setting
* `ghuconf set autoRun false` will disable automatically running `/autoruns`
* `ghuconf set autoUpdate default` will revert auto update to the default value (true)
* `ghuconf add extraRepos example/test:/src default` will subscribe to Github repo "example/test" with the path "/src" with default minified Lua setting (use global)
* `ghuconf add extraRepos example/test:/src false` will subscribe to Github repo "example/test" with the path "/src" without minified Lua files
* `ghuconf remove extraRepos example/test:/src` will unsubscribe to Github repo "example/test" (does not delete files)

## Note About Caching

CraftOS seems heavily cache files http calls. As a result, it may take up to 5 minutes for new files to be detected by `ghuupdate.lua`. If you know any way to improve this, please make an issue or PR and let's talk about it!
