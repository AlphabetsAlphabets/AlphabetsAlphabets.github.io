---
layout: post
title: 'Performing pre-shutdown tasks'
date: 2023-02-07 20:00
---

## Why I wanted to do this

I remember losing most of my notes in my second semester of diploma. It hurt my soul. Despite having a private github repository setup for said notes, the process was still manual as I had to run the commands to add, commit and then push. This made it so I only backed up my notes once a week. One time I wanted to do some deleting and stupidly I *did not* test out the script in a dummy folder beforehand. This resulted in me deleting a lot of important documents. After that experience all I wanted to do was to be able to have this backup process happen on its own. So, I came up with a simple solution: Performing the add, commit and push before the computer shutsdown. I spent some time looking at options to achieve what I wanted and I managed to find a solution I'm quite happy with.

First of all this doesn't apply to *just* before shutdowns. You can use `systemd` in a variety of ways. If you'd like to know more about what systemd is refer to [this](https://wiki.archlinux.org/title/Systemd) article and if you'd like to how to run certain scripts based on some condition refer to the article on `systemd` on the arch wiki and the [man page](https://man.archlinux.org/man/systemd.service.5#Default_Dependencies) about `systemd`.

## Creating systemd units
Tasks ran by systemd are called units and all units have the `.service` extension. These units are made by users and therefore must be placed in `~/.config/systemd/user/`[^1]. Thank the Arch Wiki because there's a [guide](https://wiki.archlinux.org/title/Systemd#Writing_unit_files) that tells you exactly how to write units. Based on the functionality desired I wrote a simple script (stored in `~/script` to keep things simple) and then made it executable with `chmod u+x <script>`.[^2]

I named the unit `backup.service` and placed it in `~/.config/systemd/user`. You can name it whatever you want, as long as it's name clearly describes its purpose. This is the content of the unit.

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
- `RemainAfterExit`, `ExecStop` is for service units that will run scripts.

`RemainAfterExit`[^3] is a must for these service units as it won't even get into an active state it will always be dead.[^4]

- `Requires=network-online.target` 

`Requires=` makes sure that `network-online.target` will be started if it isn't when this service unit activates. This is because to push to remote repository an internet connection is required.

- `After=network-online.target` 

`After=` makes sure that `network-online.target` has started. If `network-online.target` fails to start for whatever reason the script will not be executed.[^5] This ensures that the script will only execute if there is an internet connection otherwise, nothing happens.

> Something **very important** that I'd like to bring up is the help I received from [dnaka](https://github.com/dnaka91) and [Freddy](https://unix.stackexchange.com/users/332764/freddy) a unix user who helped me solve this [issue](https://unix.stackexchange.com/a/734710/527572). He also explained that if `DefaultDependencies` is removed then `shutdown.target` is implicitly included when the service unit is run!

## Working around user input
After [password authentication was shutdown](https://github.blog/changelog/2021-08-12-git-password-authentication-is-shutting-down/) in 2021, I decided to use SSH keys for authorisation. However, my SSH keys are password protected which means that user input is required. Inputs which I cannot give because when the system is shutting down the screen goes black. So, a way to circumvent this is to create a new SSH key and only use it for that specific repository. GitHub already has [documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) on how to do exactly that.

## Enabling the unit
After writing up the service unit they are not detected yet and systemd will need to know about them to do that run `sudo systemctl daemon-reload`. Then you'll need to enable it with `systemctl --user enable <service>` and there will be some output this is what I got.

```
Created symlink /home/yjh/.config/systemd/user/shutdown.target.wants/backup.service → /home/yjh/.config/systemd/user/backup.service.
```

I made some random changes and I restarted my PC. I looked at the repository through my phone and saw a new commit. A huge success!

## Closing thoughts
This actually took me a while to deal with. I spent many hours on this and even skipped class, probably not a smart idea. I was in class sure, but I was at the back doing my own thing. Anyways, the moral of the story is
1. Don't run `rm -rf` without testing it first.
2. Automate backups for redundency.

I implemented this about two years ago, and I've never been happier at my lack of data loss. I even manually backup my data once every few months to an external drive I carry around everywhere. I'm proud to say that if you threw my laptop into a volcano I would suffer no data loss!

[^1]: [~/.config/systemd/user/ where the user puts their own units.](https://wiki.archlinux.org/title/Systemd/User)
[^2]: Along side the manuals and wikipages the article on running scripts with systemd by [golinuxcloud](https://www.golinuxcloud.com/run-script-with-systemd-before-shutdown-linux/) was also very helpful.
[^3]: About [`RemainAfterExit`](https://man.archlinux.org/man/systemd.service.5#OPTIONS) will require some serching with CTRL+F.
[^4]: [`Type=oneshot` and relation to `RemainAfterExit`](https://man.archlinux.org/man/systemd.service.5#OPTIONS). Will require some searching with CTRL+F.
[^5]: Detailed info on [`Requires=`](https://man.archlinux.org/man/systemd.unit.5.en#%5BUNIT%5D_SECTION_OPTIONS). Will require searching.
