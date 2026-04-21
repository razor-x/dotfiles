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
