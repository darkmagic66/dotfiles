local lazy = require "lazy"
return {
  { "luarocks/hererocks", build = "rockspec", lazy = true },

  -- {
  --   "stevearc/conform.nvim",
  --   -- event = 'BufWritePre', -- uncomment for format on save
  --   config = function()
  --     require "configs.conform"
  --   end,
  -- },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        -- Front-Family
        "typescript-language-server",
        "html-lsp",
        "css-lsp",
        "prettierd",
        -- python
        "pyright",
        "mypy",
        "ruff",
        "black",
        "debugpy",
        -- go
        "gopls",
        "gofumpt",
        "goimports",
        "golines",
        -- c-fmailiy
        "clangd",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      automatic_installation = true,
    },
  },
  --
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "vimdoc",
        "lua",
        "bash",
        "python",
        "go",
        "cpp",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        -- markdown rendering (markview.nvim)
        "markdown",
        "markdown_inline",
        "latex",
        "typst",
        "yaml",
        "comment",
      },
    },
  },

  ------------------ User Config --------------------
  -- Lazy install
  {
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    ft = { "python", "go" },
    opts = function()
      return require "configs.null-ls"
    end,
  },

  -- {
  --   "mfussenegger/nvim-lint",
  --   event = "VeryLazy",
  --   config = function()
  --     require "configs.lint"
  --   end,
  -- },

  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
  },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {
        -- Configuration here, or leave empty to use defaults
      }
    end,

  },

  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      
      -- Map Ctrl+j to move down the list
      opts.mapping["<C-j>"] = cmp.mapping.select_next_item()
      
      -- Map Ctrl+k to move up the list
      opts.mapping["<C-k>"] = cmp.mapping.select_prev_item()
    end,
  },

  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    config = function()
      require("zen-mode").setup({
        window = {
          width = 100, 
          options = {
            number = true, 
            relativenumber = true,
          }
        },
      })
    end
  },
  ------------------ Debugger ------------------------
  {
    "mfussenegger/nvim-dap",
  },

  {
    "nvim-neotest/nvim-nio",
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  ----------------- Python --------------------------
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function(_, opts)
      local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
      require("dap-python").setup(path)
      -- require("core.utils").load_mappings "dap_python"
    end,
  },
  ---------------- Go -----------------------------
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
  },

  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
    },
    config = function(_, opts)
      require("dap-go").setup(opts)
    end,
  },
  -- GoTagAdd {json,yaml} GoMod tidy Goget {} GoTestAll

  ---------------- Markdown rendering ----------------
  -- Inline markdown/typst/latex/html previewer.
  -- Author explicitly warns: do NOT lazy-load (causes startup lag for previews).
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },

  -- Browser-based markdown preview (synchronized scrolling, KaTeX, mermaid, etc.).
  -- Uses pre-built binary via mkdp#util#install() so yarn/npm is not required.
  -- lazy = false: plugin/mkdp.vim registers a FileType autocmd that creates the
  -- buffer-local :MarkdownPreviewToggle command. Lazy-loading on ft/cmd fires
  -- AFTER the FileType event, so the first markdown buffer never gets the command.
  {
    "iamcco/markdown-preview.nvim",
    lazy = false,
    build = ":call mkdp#util#install()",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },
}
