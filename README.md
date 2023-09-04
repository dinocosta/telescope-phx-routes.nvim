# Telescope Phoenix Routes
> View and access your [Phoenix](https://github.com/phoenixframework/phoenix) routes using [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

## Table of Contents

* [Installation](#installation)
* [Setup](#setup)
* [Usage](#usage)


## Installation

Install the plugin with your preferred package manager.

```lua
-- lazy.nvim
{
    'dinocosta/telescope-phx-routes.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' }
}
```

## Setup

After installation you simply need to load the extension with:

```lua
require('telescope').load_extension('phx-routes')
```

## Usage

The extension can easily be run with the `:Telescope` command:

```
:Telescope phx-routes routes
```

Or, more conveniently, you can create a mapping for it. In this example, `space + p + r` is used:

```lua
vim.api.nvim_set_keymap(
  "n",
  "<space>pr",
  ":Telescope phx-routes routes<CR>",
  { noremap = true }
)
```
