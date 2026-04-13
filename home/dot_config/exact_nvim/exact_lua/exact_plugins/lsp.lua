return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.lsp.enable("clangd")

      vim.lsp.enable("clojure_lsp")
      -- TODO cljfmt, kondo ?

      vim.lsp.enable("gopls")
      vim.lsp.enable("golangci_lint_ls")

      vim.lsp.enable("ts_ls")
      vim.lsp.enable("biome")

      --- https://github.com/neovim/nvim-lspconfig/blob/841c6d4139aedb8a3f2baf30cef5327371385b93/lsp/lua_ls.lua#L16-L61
      vim.lsp.config("lua_ls", {
        on_init = function(client)
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
              path ~= vim.fn.stdpath("config")
              and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
            then
              return
            end
          end

          client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
            runtime = {
              version = "LuaJIT",
              path = {
                "lua/?.lua",
                "lua/?/init.lua",
              },
            },
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
              },
            },
          })
        end,
        settings = {
          Lua = {},
        },
      })
      vim.lsp.enable("lua_ls")

      vim.lsp.enable("stylua")

      vim.lsp.enable("phpactor")
      -- TODO mago ?

      vim.lsp.enable("pyright")
      vim.lsp.enable("ruff")

      vim.lsp.enable("ruby_lsp")
      vim.lsp.enable("rubocop")

      vim.lsp.enable("bashls")
      vim.lsp.enable("fish_lsp")
    end,
  },
}
