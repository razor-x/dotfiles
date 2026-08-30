local M = {}

---@module "lazy.types"
---@type LazySpec
M.spec = {
  {
    "nvim-mini/mini.completion",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "snacks_picker_input",
        callback = function()
          vim.b.minicompletion_disable = true
        end,
      })
    end,
    opts = {
      mappings = {
        force_twostep = "<C-E>",
        scroll_down = "<C-d>",
        scroll_up = "<C-u>",
      },
    },
  },
  {
    "nvim-mini/mini.snippets",
    dependencies = { "rafamadriz/friendly-snippets", "folke/snacks.nvim" },
    ---@module "mini.snippets"
    opts = function()
      local MiniSnippets = require("mini.snippets")
      return {
        snippets = { MiniSnippets.gen_loader.from_lang() },
        mappings = {
          expand = "",
          jump_next = "",
          jump_prev = "",
        },
      }
    end,
    config = function(_, opts)
      local MiniSnippets = require("mini.snippets")
      local Snacks = require("snacks")
      MiniSnippets.setup(opts)
      MiniSnippets.start_lsp_server()
      vim.keymap.set("i", "<C-Space>", function()
        MiniSnippets.expand({
          match = false,
          select = function(snippets, insert)
            Snacks.picker({
              title = "Snippets",
              layout = "vertical",
              format = "text",
              preview = "preview",
              items = vim.tbl_map(function(snippet)
                local body = type(snippet.body) == "string" and snippet.body or table.concat(snippet.body, "\n")
                return {
                  text = string.format(
                    "%s │ %s",
                    snippet.prefix or "<No prefix>",
                    snippet.desc or "<No description>"
                  ),
                  snippet = snippet,
                  preview = { text = body, ft = vim.bo.filetype },
                }
              end, snippets),
              confirm = function(picker, item)
                picker:close()
                vim.schedule(function()
                  insert(item.snippet)
                end)
              end,
            })
          end,
        })
      end, { desc = "Select snippet" })
    end,
  },
}

return M.spec
