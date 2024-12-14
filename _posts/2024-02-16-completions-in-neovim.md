---
layout: post
title: 'Completions in Neovim'
date: 2024-02-16 23:00
---

## Introduction
I decided to learn about this because why not. I remember one time I heard about omnifunc and that it's vim's built in completion. And I decided to give it a try because why not. It ended up being a pretty good experience. I also plan to use tags for navigation and code completion for a few weeks just to get a feel for this vs LSP. It will definitely be an interesting exercise and definitely one that's gonna be fun. It's also how people used to code pre-LSP.

## What are completions?
Completions is just Vim/Neovim's built in method of word completion. You can do all sorts of completions with it. Line completion, word, and even code. Code completions is done with "omnifunc" and it isn't LSP, it has nothing to do with that which is why it sucks lol. What **key difference** between autocompletion and just completions is that completions is **manual** you need to press a keybind in order to activate it. Meaning instead of suggestions appearing as you type, you need to press a keybind to get those suggestions to appear.

## A general use case of completions 
Completions are able to match words and then insert them. Making it useful for completing certain words or long functions names. Here is some code. And I wish to complete the variable name `folds_augroups`.
![](https://i.imgur.com/nDBadJP.png)

Because I find it annoying to type a variable name which is that long.

<div style="width:100%;height:0;padding-bottom:56%;position:relative;"><iframe src="https://giphy.com/embed/YWDgiOTp4FQezxZr6k" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/YWDgiOTp4FQezxZr6k"></a></p>

So, I start by typing part of it then input `ctrl+n` or `ctrl+p` then select the correct choice. You can see that if I type nothing and input `ctrl+n` anyways, I'll get able to choose from literally *every* word typed in the buffer. Completions will search beyond the current buffer too. 

> The Vim editor goes through a lot of effort to find words to complete. By default, it searches the following places:
> 1. Current file
> 2. Files in other windows
> 3. Other loaded files (hidden buffers)
> 4. Files which are not loaded (inactive buffers) 
> 5. Tag files 
> 6. All files `##included` by the current file. 
>    
>   https://neovim.io/doc/user/usr_24.html##24.3 

Although option 6 is specific to C files.

Above demonstrates a general use case. There are more specific completions such as completing a file name[^ins-completion]

## Enabling omnifunc
> I'll tell you right now the code completion provided by omnifunc is pretty bad. Go to the next section with tags for how to get accurate code completion. Keep reading if you wana learn more about omnifunc.

Using omnifunc to perform code completion is pretty much the same as using it for completions. However, it must be enabled as it is not by default. To enable it have either

```
filetype plugin on
```

or

```
filetype plugin indent on
```

What this does is basically enable a filetype plugin. Filetype plugins live in `/usr/share/nvim/runtime/ftplugin`. If you open up one of its contents, it's basically just configs. Here's a snippet of `lua.vim`.

```vim
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal comments=:---,:--
setlocal commentstring=--\ %s
setlocal formatoptions-=t formatoptions+=croql

let &l:define = '\<function\|\<local\%(\s\+function\)\='
```

These files are sourced *after* your configs. Meaning these configs *override yours*. These are buffer specific and only applies to buffers that match the filetype[^1]. Meaning that configuration above will only apply to `.lua` files.

## Using omnifunc
To use omnifunc for code completion, tags are required for completions to work. Some require both tags and providers.[^tags-or-providers]. If a provider is not required, omnifunc will just work. If it is you'll get an error message.

```
Error: Requires python3 + pynvim.  :help provider-python
```

This appeared when I wanted to use omnifunc when editing a python file without the provider. The fix was simple: installing the `pynvim` package with `pip`. Continuing with the python example just having the provider isn't enough. You also need to tell omnifunc which function to use by setting its value. Working in a python file means the value for `omnifunc` is `python3complete#Complete`. I find this out by going to `usr/share/nvim/runtime/autoload` and opening the file `python3compelete.vim`. Then I navigated to the line with the `Complete` function which is this:

```
function! python3complete#Complete(findstart, base)
```

Unforunately, the completion is very shallow. It only search for symbols in the current buffer. What's more it's not even accurate.

![](https://i.imgur.com/JHEBAQn.png)

Notice how the screenshot has the `Tews` class, but it isn't listed. Another thing is that omnifunc has support for **limited** filetypes[^omnifunc-supported-filetypes]. But, this is omnifunc working as intended. Because, omnifunc is **NOT** LSP. As mentioned at the very beginning. If you'd want LSP-**like** behavior (emphasis on **like**), look at the next section.

## Getting LSP like behaviour
There are two ways to do this
1. Tags 

How completion was done pre-lsp days. You typically do not want to use this.

2. Using omni completion 

The more modern way. Which hooks omnifunc to your LSP results so you can get access to them. Because omni completion is what you want, that section will come first.

### Omnicompletion
As long as the value `omnifunc` is set to `v:lua.vim.lsp.omnifunc` you simply need to press `<C-o><C-x>` and your completions will appear!

<iframe src="https://giphy.com/embed/g8uuuyvGcufWtoqpn6" width="480" height="270" frameBorder="0" class="giphy-embed" allowFullScreen></iframe><p><a href="https://giphy.com/gifs/g8uuuyvGcufWtoqpn6">via GIPHY</a></p>

You can easily notice the difference between manual and omnicomplete. Manual completion is when the matches the text in the current buffer. So, when I typed `Par` for `PartialOrd` I get no results. But, with omnicomplete when I type `Par` and activate it, I get `ParialOrd` and its associated documentation. To get it working you can refer to [my config](https://codeberg.org/AlphabetsAlphabets/nvim/src/branch/lazy/lua/core/lsp.lua#L13) because I do not remember where I got the code from.

### Completion using tags
#### Understanding and setup

> I'll work on a post specifically for tags in the future. But for now, I'll keep this here so that you get a complete picture.

Vim and Neovim both support the use of `ctags` also called [universial tags](https://ctags.io/) to navigate around projects. `ctags` is a completely different technology from omnifunc. You can create these tags with 

```
ctags -R .
```

> Thanks to [gpanders](https://github.com/gpanders) from the neovim IRC for how to use ctags.

But, if you have a new function or class, you'll need to run it again. And again, and again, and again. This may even take an entire night. This is a snippet from the docs:

> You might do this overnight.  
> https://neovim.io/doc/user/usr_29.html#_one-tags-file

This is what is meant by LSP-**like** behaviour. If you have LSP configured, any new functions or classes will be immediately available. No compilation neccessary. With ctags, you need to recompile it.

> I did some looking around and I can't seem to find anything solid about ctags regenerating the entire tag file when you run `ctags -R .`. It is however implied in [this issue](https://github.com/universal-ctags/ctags/issues/1420). In that same issue, it also states that larger files require more resources to generate the tag file. There are requests to generate tags for code that is new or modified. These requests are placed in the issue linked above and [this one](https://github.com/universal-ctags/ctags/issues/423) and [this comment](https://github.com/universal-ctags/ctags/issues/423#issuecomment-119265531). These two issues are linked back to [this main issue](https://github.com/universal-ctags/ctags/issues/423).

#### Using tags

> This section will be moved into it's own post once I get the time for that. For now, I'll leave this here since it's useful.

Ok, once you have the provider and the tags, we can move around the project. 
1. If your cursor is on a function and you'd like to see its implementation use `CTRL+]`, if you want to move back use `CTRL+T`.

<div style="width:100%;height:0;padding-bottom:56%;position:relative;"><iframe src="https://giphy.com/embed/0fpvY4iD5Kq2cdfN2C" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/0fpvY4iD5Kq2cdfN2C"></a></p>

2. If you don't have the name of a function run `:tag` and then press space. You'll see a dropdown of all the functions, classes, etc.

<div style="width:100%;height:0;padding-bottom:56%;position:relative;"><iframe src="https://giphy.com/embed/jlKATvOgUulyqF8WnC" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/jlKATvOgUulyqF8WnC"></a></p>

3. If you're trying to look at the definition of something, that can be done with `CTRL+}`. If you want it to be in a new window do `CTRL+w }`, that window can be closed with `:pclose`.

<div style="width:100%;height:0;padding-bottom:56%;position:relative;"><iframe src="https://giphy.com/embed/7ehwPQwZMbCppw0kMq" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/7ehwPQwZMbCppw0kMq"></a></p>

4. Searching for all symbols. You can't do this directly. You have to first open the tags file, filter each line. I used FZF for this. Then a simple `CTRL+]` will get you to its definition.

<div style="width:100%;height:0;padding-bottom:56%;position:relative;"><iframe src="https://giphy.com/embed/w0arKM56lhl31t0sXY" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/w0arKM56lhl31t0sXY"></a></p>

These are just the basics. For more details look at the tags documentation[^tags-documentation] which has some good tips regarding navigation. Anyways, that's pretty much what tags can do. 

#### Completions
To get accurate code completion, you can't use omnifunc. You should use tag completion instead, triggered with `<C-x><C-]>` while in insert mode.

<div style="width:100%;height:0;padding-bottom:56%;position:relative;"><iframe src="https://giphy.com/embed/bdRagCjZkDJaV0w0EL" width="100%" height="100%" style="position:absolute" frameBorder="0" class="giphy-embed" allowFullScreen></iframe></div><p><a href="https://giphy.com/gifs/bdRagCjZkDJaV0w0EL"></a></p>

> I tried to get tag completion through omnifunc working, but it didn't. I followed the instructions [here](https://neovim.io/doc/user/insert.html#ft-c-omni) for `c` but when I used the keybinds to trigger omnifunc, nothing appeared. If you manage to get it working, feel free to share it with me :D.

## Closing
This took me a while to write as I had to do it in between school. I also have assignments but I decided this was more fun and interesting. Not the greatest idea, that much I can tell you. But, it is fun though. I did learn a lot about how to get code-completions without LSP.


[^1]: https://neovim.io/doc/user/usr_41.html##41.12
[^ins-completion]: A full list of completion types can be found in the [insert completion section](https://neovim.io/doc/user/insert.html##ins-completion).
[^tags-or-providers]: Start reading from [compl-omni-filetypes](https://neovim.io/doc/user/insert.html##compl-omni-filetypes). 
[^omnifunc-supported-filetypes]: A full list specified [here](https://neovim.io/doc/user/insert.html##compl-omni-filetypes)
[^tags-documentation]: https://neovim.io/doc/user/usr_29.html#29.1
