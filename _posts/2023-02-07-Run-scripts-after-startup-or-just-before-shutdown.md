---
layout: post
title: "Running scripts just before shutdown"
categories: linux
---

It doesn't *just* apply to just before shutdowns, the article is only titled as such as it fits *my* use case. This applies to everything, at a specific time or just after startup. `systemd` is what will handle all of this. If you'd like to know more about what systemd is refer to [this](https://wiki.archlinux.org/title/Systemd) article and how to run certain scripts basde on some condition refer to the article on `systemd` on the arch wiki and the [man page](https://man.archlinux.org/man/systemd.service.5#Default_Dependencies) about `systemd`.

These tasks ran just before shutdown are called units and all units are written in a `.service` file. Since these are serviecs made by us the user they must be placed in `~/.config/systemd/user/`[^1]. This article will about how to setup these service files. As for the convention and syntax for each file refer to another source. One method is browse and read through a couple `.service` files. Or you can take a look at this [section](https://wiki.archlinux.org/title/Systemd#Writing_unit_files) in the arch wiki about systemd.

The script I want to be run just before shutdown is simple. It will:
1. `cd` into where I place my notes.
2. use `git` to stage changes, commit and push.

There are a few things to do with your script:
1. Store it somewhere. I decided to store it in `~/scripts/` to keep things simple. 
2. Make it executable with `chmod u+x <script>`.[^2]

Now, create the `.service` file in the appropriate directory above. Name it whatever you want, since this is a backup form my notes I decided to name it `backup.service` and this is what it looks like.

```
[Unit]
Description=Backup obsidian notes before shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/home/yjh/scripts/backup.fish

[Install]
WantedBy=shutdown.target
```

> It took me a while to figure out what the purpose of `[Install]` is and if you'd like to know more take a look at the [man page](https://man.archlinux.org/man/systemd.unit.5.en#%5BINSTALL%5D_SECTION_OPTIONS) for this.

These units are not detected yet and systemd will need to know about them to do that run `sudo systemctl daemon-reload`. After making the unit known you'll need to install it with `systemctl --user enable <service>` and there will be some output this is my output is like.

```
Created symlink /home/yjh/.config/systemd/user/shutdown.target.wants/backup.service → /home/yjh/.config/systemd/user/backup.service.
```

[^1]: [~/.config/systemd/user/ where the user puts their own units.](https://wiki.archlinux.org/title/Systemd/User)
[^2]: Along side the manuals and wikipages the article on running scripts with systemd by [golinuxcloud](https://www.golinuxcloud.com/run-script-with-systemd-before-shutdown-linux/) was also very helpful.
