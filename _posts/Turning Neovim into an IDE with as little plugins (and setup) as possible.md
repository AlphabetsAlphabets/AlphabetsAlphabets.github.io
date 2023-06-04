---
layout: post
title: "Turning Neovim into an IDE with as little plugins (and setup) as possible."
categories: nvim, neovim
---

When you’re working in Visual Studio or Visual Studio Code (which isn’t technically an IDE), or JetBrains it has everything setup for you. You don’t need to download anything special. You download the app itself, you open, you code. When moving to Neovim or vim you’ll notice you need to learn how to configure a plugin with either Lua (Neovim only) or Vimscript. A plugin may be written in either one which means plugin authors may provide configuration examples of their plugin in either language which means you’ll need to learn both to some extent, although more recent plugins use Lua now. Which is why I wrote this article, I want to provide a list of plugins that will require minimal setup to use. So that you won’t need to waste time configuring this or that. You install, you code.

> It should be made clear this is not an article about how to configure neovim or vim with lua. But, I will cover the bare minimum required. The purpose of this article is to tell you what plugins to install, a large majority of suggested plugins will work out of the box. If you’d like to learn how to configure neovim with Vimscript or Lua I’ll consider writing an article about it if there are enough requests for one, however, I highly suggest [this](https://vonheikemen.github.io/devlog/tools/configuring-neovim-using-lua/) article as it does a great job at providing an introduction.

So, let’s talk about the biggest feature of an IDE has. LSP and autocomplete. For those that don’t know. There is a difference between autocomplete and LSP, the main one is that auto complete creates a pop-up that lets you choose words most similar to the one your typing. LSP is the one responsible for showing documentation and functions, without it you’ll just have a very fancy text editor. LSP is what you really want, it does symbol searching which means finding function references, where variables are used, etc., and go to definition. Armed with that information, let’s get into the meat and bones of this article.

# Notes on configuration

This applies to both vim and neovim. If you’re new to vim or neovim here’s a few quick tips to get things started. If you’re already familiar with configuration then feel free to skip this section.

When configuring neovim or vim, after changes are made you’ll need to use the so % command for the changes to take affect, this is called sourcing. Commands are started by typing “:” then the command name. In this case `:so%`.

Your configuration file is called `.vimrc` (for vim) or `init.vim` (for neovim) will live in different locations depending on your operating system. It is important to find out where your configuration file will be at. Please refer to this table from an [SO](https://vi.stackexchange.com/questions/12579/neovim-setup-on-ms-windows/12596#12596) answer by user jamessan. If the file or directory doesn’t exist, create it.

```
OS         | Vim        | nvim
-----------|------------|---------------------
Windows    | ~/vimfiles | ~/AppData/Local/nvim
*nix/macOS | ~/.vim     | ~/.config/nvim
```

3. This applies to neovim only. All lua files will be placed in a folder called “lua” in the same folder where your neovim config file will be at.

```
.

├── init.vim <-- this is the config file
├── lua
│  ├── calc.lua
│  ├── custom.lua
│  ├── dash.lua
│  ├── keymaps.lua
│  ├── packages.lua
│  ├── plugins.lua
│  ├── scratchpad.lua
│  └── settings.lua
├── plugin
│  └── packer_compiled.lua
```

For example this is what my nvim directory looks like (with other files removed), all of my lua files are inside the lua folder.

4. Your lua files will not be included in your configurations automatically. They must be explicitly imported. If for example, I want to include the configurations made in dash.lua inside init.vim I must have the line `lua require(‘dash’)`. It is important that there is no file extension.

# Installing plugins

You need to install a plugin using a plugin manager. There are many different kinds but I suggest packer. Refer to the quickstart section to have it installed, it is a simple process. After it has been installed, you’ll need to use it and packer is configured using Lua, so, you’ll need to create a file which can be called anything but for the purposes of this article it will be packages.lua. I’ve also marked optional plugins which are not required but are nice to have.

Then paste the following inside *packages.lua*. Since it is a lua file, remember to keep the file inside of the lua folder.

```
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
 use 'wbthomason/packer.nvim'
 use {'neoclide/coc.nvim', branch = 'release'}
 use 'https://github.com/tpope/vim-commentary' -- optional


 -- git integration (optional)
 use 'https://github.com/lewis6991/gitsigns.nvim'
 use 'https://github.com/tpope/vim-fugitive'


 -- Telescope - file browsing
 use 'nvim-lua/popup.nvim'
 use 'nvim-lua/plenary.nvim'
 use 'nvim-telescope/telescope.nvim'
end)
```

The plugins have not been installed yet. To install plugins make sure you source the file then run `:PackerInstall`, a window the the left will open and begin installing plugins. To update plugins run `:PackerUpdate`.

Now to explain what each plugin does.

> To clarify I will tell you what plugins you should install, as for how to use them I will not be covering that. As that would add unnecessary bloat to the article, furhtermore, learning how to use a plugin from the repository itself would be much more effective. If you’re worried about documentation, don’t. The authors are all extremely verbose which is a good thing.

1. [coc.nvim](https://github.com/neoclide/coc.nvim) is for autocomplete and LSP. The autocomplete will work out of the box, the LSP will require minor setup. You’ll need to install it and to do that refer to this page on the repository and follow the links.
2. [vim-commentary](https://github.com/tpope/vim-commentary) is to comment out multiple lines of code at once.
3. [gitsigns.nvim](https://github.com/tpope/vim-commentary) will provide git symbols the green and yellow lines among other things when editing. Will work out of the box, no setup necessary.
4. [vim-fugitive](https://github.com/tpope/vim-fugitive) is a plugin for git integration within neovim. So, you don’t have to leave neovim and re-enter it.
5. popup.nvim and plenary.nvim are required by telescope.nvim.
6. [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) is a fuzzy finder over a list but has other functionality. the main purpose of telescope is for switching between files. It is highly extensible and has many plugins to support telescope’s integration with other tools. There exists an extension for coc.nvim and it is fantastic.

All of the plugins listed have reasonable defaults and require no configuration. Except for coc.nvim, even so, the only “configuration” is finding and installing the appropriate language servers which doesn’t take long.

It is highly recommended that you do in fact look through how to use each plugin in detail. As you will learn how to utlize each of them to their maximum potential. However, this should be done only after you’ve gotten comfortable with using the plugin and have been using it consistently. As there’s no point in investing so much time into something you won’t be using in a while. The plugins listed above are ones that I have used on a daily basis for years and for me taking the time to sift through documentation is an excellent investment.
