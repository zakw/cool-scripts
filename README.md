<!--
SPDX-FileCopyrightText: Copyright (c) Zak Whaley
SPDX-License-Identifier: MIT
-->

# [neat](neat.sh)
`neat` is a handy utility to help `git clean` your workspace without deleting files you'd like to keep such as IDE
configuration, local dotfiles, etc.

`git clean`'s `-x` (all untracked) and `-X` (only ignored) flags are both used to find and delete local files not in
the repository such as build artifacts, but their default behavior can often be too aggressive in my opinion.

What `neat` effectively does is to provide a second-layer of "ignore" that acts as a "keep". It's useful for files that
you don't want to commit to the repo, but also don't want to blow away when cleaning build artifacts like local
workspace configuration.

It uses a series of `git clean`'s [`-e <pattern>`](https://git-scm.com/docs/gitignore#_pattern_format) flags to specify file patterns of items to protect.

## Usage
```
neat [-h|--help] [-n|--dry-run] [-f|--force] [-u|--untracked] [-k|--keep <pattern> ...] [-s|--show-command] [-l|--list-patterns]
```
### Setup
Place a `.neat` file in your repo root that follows typical [.gitignore patterns](https://git-scm.com/docs/gitignore#_pattern_format)
with one modification: if the last character is a `/`, then it automatically adds an additional term of `<pattern>**`
to also keep all subdirectories and files.

Example `.neat` file:
```
# Keep local IDE workspace files in our root
/.idea/
/.vs/
```

Once you [install](#installation) the script, you can run this in your repo to see a dry-run of what would be cleaned:
```
neat -n
```

It's very useful when building lists of patterns you'd like to place in your `.neat` file.

`neat` preserves untracked files by default, but you can clean them up by providing the `-u` flag.

> **Caution:** By default, `neat` will perform a dry-run and have you confirm the operation, so be *extremely* careful when
> adding the `-f` flag.

### Local Customizations
Perhaps you have personal workspace files, `.env` files, test data, etc. that you don't want to (or can't) commit
`.neat` rules for to the repo.

As a byproduct of how `neat` works, if you add `/.neat-*` to both your `.gitignore` and your `.neat` file, then you can
have local `neat` user rules just for you in files named like `.neat-local` and `.neat-userName` which will persist
across `neat` invocations.

`.gitignore`
```
# Don't commit our local .neat keep lists!
/.neat-*
```

`.neat`
```
# Don't blow away our local .neat keep lists!
/.neat-*
```

# Installation

I might make an install or setup script at some point, but for now, here are instructions on where to put it on your system.

Happy cleaning!

## Available to all users

Copy it to `/usr/local/bin` and mark it as executable for everyone.
```
sudo cp neat.sh /usr/local/bin/neat
sudo chmod a+x /usr/local/bin/neat
```

## Local to your user

Copy it to `~/bin` and mark it as executable for you.
```
cp neat.sh ~/bin/neat
chmod +x ~/bin/neat
```

# Licensing
This repository uses a dual-licensing structure between the main codebase as well as configuration, snippets, and metadata.

* **Core Source Code & Scripts:** Licensed under the [MIT License (MIT)](LICENSE)
* **Configurations, Examples, & Metadata:** Licensed under the [MIT No Attribution License (MIT-0)](LICENSES/MIT-0.txt)

<!-- REUSE-IgnoreStart -->
Individual files contain standard SPDX headers (e.g. `SPDX-License-Identifier: MIT`) to ensure compatibility.
<!-- REUSE-IgnoreEnd -->
