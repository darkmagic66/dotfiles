-- EXAMPLE
-- on_attach/on_init/capabilities are applied globally via
-- NvChad's M.defaults() -> vim.lsp.config("*", ...) + LspAttach autocmd.
-- Per-server we only need to enable; explicit config calls below document intent.

local servers = {
  "html",
  "cssls",
  "clangd",
  "ts_ls",
  "pyright",
  "gopls",
  "jdtls",
}

-- lsps with default config (inherits * defaults from NvChad)
for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {})
end

-- python: restrict to python filetype
vim.lsp.config("pyright", {
  filetypes = { "python" },
})

-- go: custom cmd, filetypes, root_markers, settings
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
      },
    },
  },
})

-- java: jdtls via mason, runs on the mise-managed JDK.
-- Neovim inherits the shell environment, so JAVA_HOME is normally set by mise
-- when the terminal is inside this project. Fall back to the mise install path.
local java_home = vim.env.JAVA_HOME or "/Users/yuki/.local/share/mise/installs/java/21"

-- Optional jars for DAP/test integration, installed by mason.
local mason_packages = vim.fn.stdpath "data" .. "/mason/packages"
local function mason_jars(pattern)
  local found = vim.fn.glob(mason_packages .. pattern, true)
  return vim.tbl_filter(function(p)
    return p ~= ""
  end, vim.split(found, "\n"))
end

local bundles = mason_jars "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
vim.list_extend(bundles, mason_jars "/java-test/extension/server/*.jar")
-- Spring Boot / Spring Framework (STS4) jdtls extensions. The jar list comes
-- from spring-boot.nvim so it stays in sync with the language server that
-- plugin launches; see the Java / Spring Boot section in plugins/init.lua.
vim.list_extend(bundles, require("spring_boot").java_extensions())

-- lombok: bundled with the mason jdtls package; the agent must reach the JVM.
local lombok_jar = mason_packages .. "/jdtls/lombok.jar"

vim.lsp.config("jdtls", {
  cmd = { "jdtls", "--jvm-arg=-javaagent:" .. lombok_jar },
  filetypes = { "java" },
  root_markers = {
    "gradlew",
    "settings.gradle",
    "settings.gradle.kts",
    "build.gradle",
    "build.gradle.kts",
    "mvnw",
    "pom.xml",
    ".git",
  },
  init_options = {
    bundles = bundles,
    -- One workspace per project, kept out of the source tree.
    workspace = vim.fn.stdpath "data"
      .. "/jdtls/"
      .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
  },
  settings = {
    java = {
      jdt = {
        ls = {
          java = { home = java_home },
        },
      },
      import = {
        gradle = { enabled = true, wrapper = { enabled = true } },
      },
      configuration = { updateBuildConfiguration = "automatic" },
      signatureHelp = { enabled = true },
      -- Lombok annotations (@Data, @Slf4j, ...) are only understood with the
      -- agent above plus this switch.
      lombokSupport = { enabled = true },
      inlayHints = { parameterNames = { enabled = "literals" } },
      completion = {
        favoriteStaticMembers = {
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
        },
      },
    },
  },
})

-- enable all configured servers
vim.lsp.enable(servers)

-- Neovim keeps inlay hints off by default; turn them on for Java only, since
-- jdtls is the engine that reports them (see java.inlayHints above).
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "jdtls" then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})