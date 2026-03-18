local on_attach = _G.dotfiles_lsp_on_attach

local function java_root_dir(bufname)
  local path = bufname ~= "" and bufname or vim.api.nvim_buf_get_name(0)
  return vim.fs.root(path, { "BUILD.bazel", ".git", "mvnw", "gradlew" })
end

local function bazel_workspace(dir)
  return vim.fs.root(dir, { "WORKSPACE", "WORKSPACE.bazel" })
end

local function run_systemlist(cmd, cwd)
  local wrapped = cmd
  if cwd and cwd ~= "" then
    wrapped = "cd " .. vim.fn.shellescape(cwd) .. " && " .. cmd
  end

  local out = vim.fn.systemlist(wrapped)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out
end

local function find_bazel_target(package_dir, workspace_root)
  local rel = package_dir:sub(#workspace_root + 2)
  local lines = run_systemlist(
    "bzl query " .. vim.fn.shellescape("//" .. rel .. ":all") .. " --output=label_kind",
    workspace_root
  )
  if not lines then
    return nil
  end

  local function pick(preferred)
    for _, line in ipairs(lines) do
      local kind, label = line:match("^(%S+)%s+rule%s+(%S+)$")
      if kind and label and not kind:match("^_") and not label:match("%.classpath$") and preferred(kind) then
        return label
      end
    end
    return nil
  end

  return pick(function(kind) return kind:match("java_library$") end)
    or pick(function(kind) return kind:match("java") ~= nil end)
end

local function classpath_jars(workspace_root, target)
  local cp_target = target .. ".classpath"
  if not run_systemlist("bzl build " .. vim.fn.shellescape(cp_target), workspace_root) then
    return nil
  end

  local cp_files = run_systemlist(
    "bzl cquery " .. vim.fn.shellescape(cp_target) .. " --output=files",
    workspace_root
  )
  if not cp_files then
    return nil
  end

  local cp_rel = nil
  for _, line in ipairs(cp_files) do
    if line:match("^bazel%-bin/.+%.classpath$") or line:match("^bazel%-out/.+%.classpath$") then
      cp_rel = line
      break
    end
  end
  if not cp_rel then
    return nil
  end

  local ok, entries = pcall(vim.fn.readfile, workspace_root .. "/" .. cp_rel)
  if not ok then
    return nil
  end

  local jars = {}
  for _, entry in ipairs(entries) do
    if entry ~= "" then
      local abs
      if vim.startswith(entry, "../maven/") then
        abs = workspace_root .. "/bazel-bin/external/" .. entry:sub(4)
      else
        abs = workspace_root .. "/bazel-bin/" .. entry
      end

      if vim.fn.filereadable(abs) == 1 then
        table.insert(jars, abs)
      end
    end
  end
  return jars
end

local function write_if_changed(path, lines)
  local current
  local ok, existing = pcall(vim.fn.readfile, path)
  if ok then
    current = table.concat(existing, "\n")
  end

  local desired = table.concat(lines, "\n")
  if current ~= desired then
    vim.fn.writefile(lines, path)
    return true
  end
  return false
end

local function write_eclipse_files(root_dir, jars)
  local project_name = vim.fn.fnamemodify(root_dir, ":t")
  local project_changed = write_if_changed(root_dir .. "/.project", {
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<projectDescription>",
    "  <name>" .. project_name .. "</name>",
    "  <buildSpec><buildCommand>",
    "    <name>org.eclipse.jdt.core.javabuilder</name>",
    "  </buildCommand></buildSpec>",
    "  <natures><nature>org.eclipse.jdt.core.javanature</nature></natures>",
    "</projectDescription>",
  })

  local cp = { '<?xml version="1.0" encoding="UTF-8"?>', "<classpath>" }
  for _, rel in ipairs({ "src/main/java", "src/test/java", "src/benchmark/java" }) do
    if vim.fn.isdirectory(root_dir .. "/" .. rel) == 1 then
      table.insert(cp, '  <classpathentry kind="src" path="' .. rel .. '"/>')
    end
  end
  table.insert(cp, '  <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>')
  for _, jar in ipairs(jars or {}) do
    table.insert(cp, '  <classpathentry kind="lib" path="' .. jar .. '"/>')
  end
  table.insert(cp, '  <classpathentry kind="output" path=".jdtls-bin"/>')
  table.insert(cp, "</classpath>")

  local classpath_changed = write_if_changed(root_dir .. "/.classpath", cp)
  return project_changed or classpath_changed
end

local function refresh_bazel_classpath(root_dir)
  local workspace_root = bazel_workspace(root_dir)
  if not workspace_root then
    return false
  end

  local target = find_bazel_target(root_dir, workspace_root)
  if not target then
    return false
  end

  local jars = classpath_jars(workspace_root, target)
  if not jars or #jars == 0 then
    return false
  end

  return write_eclipse_files(root_dir, jars)
end

local function jdtls_config(root_dir)
  local project_name = root_dir:gsub("[/\\]", "-")
  return {
    cmd = { "jdtls", "-data", vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name },
    root_dir = root_dir,
    on_attach = on_attach,
    init_options = { bundles = {} },
  }
end

local function restart_jdtls(cfg)
  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    client:stop()
  end

  vim.defer_fn(function()
    local ok, jdtls = pcall(require, "jdtls")
    if ok then
      jdtls.start_or_attach(cfg)
    end
  end, 500)
end

pcall(vim.api.nvim_buf_del_user_command, 0, "JdtlsRefreshClasspath")
vim.api.nvim_buf_create_user_command(0, "JdtlsRefreshClasspath", function()
  local root = java_root_dir(vim.api.nvim_buf_get_name(0))
  if not root then
    return
  end

  refresh_bazel_classpath(root)
  restart_jdtls(jdtls_config(root))
end, {})

local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return
end

local root = java_root_dir(vim.api.nvim_buf_get_name(0))
if not root then
  return
end

jdtls.start_or_attach(jdtls_config(root))
