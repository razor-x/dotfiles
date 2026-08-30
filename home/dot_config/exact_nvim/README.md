# Neovim Config

## Standalone Install

The included Neovim config may be installed independently

```sh
curl -fsSL https://raw.githubusercontent.com/razor-x/dotfiles/main/nvimrc.sh | sh
```

To install it as an isolated app,
pass the desired `NVIM_APPNAME` as the first argument

```sh
curl -fsSL https://raw.githubusercontent.com/razor-x/dotfiles/main/nvimrc.sh | sh -s -- razor-x
```

## Architecture

1. Every `plugins/*.lua` file must export a `LazySpec`.

   - The `plugins/*.lua` files are organized by interface, not by individual plugin.
   - Every such file must include at least one real plugin that justifies the file.

1. Built-in mappings belong in the corresponding interface's plugin spec.

   - Use `init` for built-in options or mappings that must be set before or independently of plugin setup.

1. Plugin-specific mappings should live on the corresponding plugin spec whenever possible.

   - Use `keys` for plugin entrypoint mappings when possible.
   - Use `config` for plugin-dependent mappings or setup.

1. Toggles use `yo{key}` for global state. When a toggle supports buffer- or window-local state, replace `y` with `\` for its local form: `\o{key}`.

1. Annotate a plugin's config with its LuaLS module and config type immediately before `opts` when the plugin publishes them:

   ```lua
   ---@module "plugin-module"
   ---@type PluginConfig
   opts = {}
   ```

1. When a plugin creates a Lua global, add its library path and global name to the `lazydev.nvim` `library` list in `init.lua` so LuaLS loads that plugin's types when the global is used.
