---
layout: post
title: "Scheduleing pre-shutdown tasks with systemd"
categories: linux
---

It doesn't *just* apply to just before shutdowns, the article is only titled as such as it fits *my* use case. This applies to everything, at a specific time or just after startup. `systemd` is what will handle all of this. If you'd like to know more about what systemd is refer to [this](https://wiki.archlinux.org/title/Systemd) article and if you'd like to how to run certain scripts based on some condition refer to the article on `systemd` on the arch wiki and the [man page](https://man.archlinux.org/man/systemd.service.5#Default_Dependencies) about `systemd`.

These tasks ran just before shutdown are called units and all units are written in a `.service` file. Since these are serviecs made by us the user they must be placed in `~/.config/systemd/user/`[^1]. This article will about how to setup these service files. As for the convention and syntax for each file refer to another source. One method is browse and read through a couple `.service` files. Or you can take a look at this [section](https://wiki.archlinux.org/title/Systemd#Writing_unit_files) in the arch wiki about systemd.

The script I want to be run just before shutdown is simple. It will:
1. `cd` into where I place my notes.
2. use `git` to stage changes, commit and push.

There are a few things to do with your script:
1. Store it somewhere. I decided to store it in `~/scripts/` to keep things simple. 
2. Make it executable with `chmod u+x <script>`.[^2]

Now, create the `.service` file in the appropriate directory above. Name it whatever you want, since this is a backup for my notes I decided to name it `backup.service` and this is what it looks like.

```
[Unit]
Description=Backup obsidian notes before shutdown
DefaultDependencies=no
Requires=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStop=fish /home/yjh/scripts/backup.fish

[Install]
WantedBy=default.target shutdown.target
```


> It took me a while to figure out what the purpose of `[Install]` is and if you'd like to know more take a look at the [man page](https://man.archlinux.org/man/systemd.unit.5.en#%5BINSTALL%5D_SECTION_OPTIONS) for this.

There are a few items that relate to my use case of (1) running scripts before shutdown and (2) pushing a local repo to a remote repsitory. 

> Something **very important** that I'd like to bring up is the help I received from [dnaka](https://github.com/dnaka91) and [Freddy](https://unix.stackexchange.com/users/332764/freddy) a unix user who helped me solve this [issue](https://unix.stackexchange.com/a/734710/527572).

- `RemainAfterExit`, `ExecStop` is for service units that will run scripts.

`RemainAfterExit`[^3] is a must for these service units as it won't even get into an active state it will always be dead.[^4]

- `Requires=network-online.target` and `After=network-online.target` 

`Requires=` makes sure that `network-online.target` will be started if it isn't when this service unit activates. `After=` makes sure that `network-online.target` has started. If `network-online.target` fails to start for whatever reason the script will not be executed.[^5] This is important because pushing to a remote repository requires a network connection. An additional note is that with the use of the git credential manager, pushing to a remote repository will require authorization and the service will always fail as it is impossible to provide any user input when the system is getting ready to shutdown. A way to circumvent this is to create an SSH key and only use SSH for that specific repository, GitHub already has [documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) on how to do exactly that.

After writing up the service unit they are not detected yet and systemd will need to know about them to do that run `sudo systemctl daemon-reload`. Then you'll need to enable it with `systemctl --user enable <service>` and there will be some output this is what I got.

```
Created symlink /home/yjh/.config/systemd/user/shutdown.target.wants/backup.service → /home/yjh/.config/systemd/user/backup.service.
```

I created some random changes where I store my notes and after I restarted my PC, I took a look at the repository web and found that they have been committed. A huge success!

---

[^1]: [~/.config/systemd/user/ where the user puts their own units.](https://wiki.archlinux.org/title/Systemd/User)
[^2]: Along side the manuals and wikipages the article on running scripts with systemd by [golinuxcloud](https://www.golinuxcloud.com/run-script-with-systemd-before-shutdown-linux/) was also very helpful.
[^3]: About [`RemainAfterExit`](https://man.archlinux.org/man/systemd.service.5#OPTIONS) will require some serching with CTRL+F.
[^4]: [`Type=oneshot` and relation to `RemainAfterExit`](https://man.archlinux.org/man/systemd.service.5#OPTIONS). Will require some searching with CTRL+F.
[^5]: Detailed info on [`Requires=`](https://man.archlinux.org/man/systemd.unit.5.en#%5BUNIT%5D_SECTION_OPTIONS). Will require searching.
