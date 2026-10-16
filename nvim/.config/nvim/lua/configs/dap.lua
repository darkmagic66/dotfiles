-- Java / Spring Boot debugging through jdtls.
--
-- java-debug ships as a bundle inside jdtls, so there is no standalone adapter
-- binary: jdtls hands out a debug session port on request, and resolves the
-- executable main classes together with the classpath java-debug needs.

local dap = require "dap"

local function jdtls()
  return vim.lsp.get_clients({ name = "jdtls" })[1]
end

local function execute(client, command, args, bufnr)
  local resp = client:request_sync("workspace/executeCommand", {
    command = command,
    arguments = args,
  }, 30000, bufnr)

  if not resp or resp.err then
    return nil
  end
  return resp.result
end

dap.adapters.java = function(callback)
  local client = jdtls()
  if not client then
    vim.notify("jdtls is not running - open a Java file first", vim.log.levels.ERROR)
    return
  end

  client:request("workspace/executeCommand", { command = "vscode.java.startDebugSession" }, function(err, port)
    if err or not port then
      vim.notify("java-debug could not start a session: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    callback { type = "server", host = "127.0.0.1", port = port }
  end, 0)
end

-- One launch configuration per executable main class in the workspace, each
-- with its classpath and module path already resolved.
local function main_class_configs(bufnr)
  local client = jdtls()
  if not client or vim.bo[bufnr].filetype ~= "java" then
    return {}
  end

  local classes = execute(client, "vscode.java.resolveMainClass", nil, bufnr)
  if type(classes) ~= "table" then
    return {}
  end

  local configs = {}
  for _, class in ipairs(classes) do
    local paths = execute(client, "vscode.java.resolveClasspath", { class.mainClass, class.projectName }, bufnr)
    configs[#configs + 1] = {
      type = "java",
      request = "launch",
      name = "Launch " .. (class.projectName or "") .. ": " .. class.mainClass,
      mainClass = class.mainClass,
      projectName = class.projectName,
      modulePaths = paths and paths[1] or nil,
      classPaths = paths and paths[2] or nil,
    }
  end
  return configs
end

if dap.providers and dap.providers.configs then
  dap.providers.configs.java = main_class_configs
end

dap.configurations.java = {
  {
    type = "java",
    request = "attach",
    name = "Attach to JVM (port 5005)",
    hostName = "127.0.0.1",
    port = 5005,
  },
}
