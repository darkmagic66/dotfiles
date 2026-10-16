local lazy = require "lazy"
return {
  { "luarocks/hererocks", build = "rockspec", lazy = true },

  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Java: Spring's own Checkstyle-aligned formatter. It reads the file on
      -- stdin and writes the result to stdout (the "Loading formatter from ..."
      -- banner goes to stderr, so it is safe here).
      opts.formatters = opts.formatters or {}
      opts.formatters.spring_javaformat = {
        command = "spring-javaformat",
        args = { "format", "--stdin" },
        stdin = true,
      }
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.java = { "spring_javaformat" }
    end,
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  -- mason.nvim v2 dropped its own "ensure_installed" option. Installs are now
  -- delegated to mason-lspconfig (language servers) and mason-tool-installer
  -- (formatters / linters / debug adapters).
  {
    "mason-org/mason.nvim",
  },
  {
    "mason-org/mason-lspconfig.nvim",
    event = "VeryLazy",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      -- These are nvim-lspconfig server names, not mason package names.
      -- Config + enable happens in configs/lspconfig.lua.
      ensure_installed = {
        "lua_ls",
        -- frontend
        "ts_ls",
        "html",
        "cssls",
        -- python
        "pyright",
        -- go
        "gopls",
        -- c-family
        "clangd",
        -- java
        "jdtls",
      },
      automatic_enable = false,
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        "stylua",
        "prettierd",
        -- python
        "mypy",
        "ruff",
        "black",
        "debugpy",
        -- go
        "gofumpt",
        "goimports",
        "golines",
        -- java
        "java-debug-adapter",
        "java-test",
      },
    },
  },
  --
  {
    "nvim-treesitter/nvim-treesitter",
    -- NvChad (nvim-treesitter "main" branch) does not install parsers on its
    -- own anymore; it only exposes :TSInstallAll and a "build" step. Install
    -- the list below at startup so a fresh machine self-heals (no-op when the
    -- parsers already exist).
    config = function(_, opts)
      require("nvchad.configs.treesitter")
      if type(opts.ensure_installed) == "table" then
        require("nvim-treesitter").install(opts.ensure_installed)
      end
    end,
    opts = {
      ensure_installed = {
        "vim",
        "vimdoc",
        "lua",
        "bash",
        "python",
        "go",
        "java",
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
    config = function()
      require "configs.dap"
    end,
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

  ---------------- Java / Spring Boot ----------------
  -- Launches the STS4 Spring Boot language server installed via mason and wires
  -- the classpath handshake jdtls needs (without it: no beans, no endpoints, no
  -- application.properties / .yml property completion). Discovers the server jar
  -- and the jdtls extension jars from mason on its own.
  {
    "JavaHello/spring-boot.nvim",
    ft = "java",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("spring_boot").setup {}
    end,
  },

  ---------------- Markdown rendering ----------------
  -- Inline markdown/typst/latex/html previewer.
  -- Author explicitly warns: do NOT lazy-load (causes startup lag for previews).
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    -- Auto-render disabled; toggle manually with <leader>mt / <leader>mT
    opts = {
      preview = {
        enable = false,
        -- Default filetypes + html (html renderer = tag conceal + decoration, not full page render)
        filetypes = { "markdown", "quarto", "rmd", "typst", "asciidoc", "html" },
      },
    },
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
