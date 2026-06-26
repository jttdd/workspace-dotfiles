local on_attach = _G.dotfiles_lsp_on_attach

local refresh_jobs = {}
local source_dirs_cache = {}

local logs_backend_source_root_whitelist = {
  "domains/streaming",
  "domains/event-platform/libs/assigner-commons",
  "domains/event-platform/libs/assigner-commons-test-utils",
  "domains/event-platform/libs/assigner-utils",
  "domains/event-platform/libs/autoscaling-utils",
  "domains/event-platform/libs/k8s-coordinator",
  "domains/event-platform/libs/notifications",
  "domains/event-platform/libs/notifications-test-utils",
  "domains/event-platform/libs/org-routing",
  "domains/event-platform/libs/persistence-control-plane",
  "domains/event-platform/libs/routes",
  "domains/event-platform/libs/slicelet-client",
  "domains/event-platform/libs/slicer-model",
  "domains/event-platform/libs/storage-cells",
  "domains/event-platform/libs/topology",
  "domains/event-platform/libs/workload",
  "domains/event-platform/libs/workload-admin",
  "domains/event-platform/libs/workload-test-utils",
  "domains/event-platform/shared/libs/commons",
  "domains/event-platform/shared/libs/commons-core",
  "domains/event-platform/shared/libs/commons-test-utils",
  "domains/event-platform/shared/libs/dd-metrics",
  "domains/event-platform/shared/libs/dd-metrics-test-utils",
  "domains/event-platform/shared/libs/metrics-querier-client",
  "domains/event-platform/shared/libs/mongo",
  "domains/event-platform/shared/libs/mongo-test-utils",
  "domains/event-platform/shared/libs/object-storage",
  "domains/event-platform/shared/libs/object-storage-provider",
  "domains/event-platform/shared/libs/service",
  "domains/event-platform/shared/libs/service-test-utils",
  "domains/event-platform/shared/libs/vault-tools",
  "domains/commons/shared/libs/dd-util",
  "domains/commons/shared/libs/scheduled",
  "domains/commons/shared/libs/service-directory-client",
  "domains/commons/shared/libs/telemetry",
  "domains/rpc/shared/libs/ddgrpc",
  "domains/rpc/shared/libs/health",
  "domains/rpc/shared/libs/interceptors",
  "domains/rpc/shared/libs/metrics",
  "domains/rpc/shared/libs/status",
  "domains/rpc/shared/libs/test-utils",
  "domains/rpc/shared/libs/utils",
  "domains/autoscaling/libs/predictivescaling",
  "domains/event-store/libs/toto-inference-grpc-client",
  "domains/fabric/libs/fabric-client",
  "domains/logs/shared/libs/dd-internal-authentication",
  "domains/streaming-engine/libs/domain",
}

local function normalize(path)
  local absolute = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
  local normalized = vim.fs.normalize(absolute)
  return vim.uv.fs_realpath(normalized) or normalized
end

local function starts_with_path(path, prefix)
  return path == prefix or path:sub(1, #prefix + 1) == prefix .. "/"
end

local function root_with_markers(path, markers)
  local root = vim.fs.root(path, markers)
  if root then
    return normalize(root)
  end
  return nil
end

local function bazel_workspace(path)
  return root_with_markers(path, { "WORKSPACE", "WORKSPACE.bazel" })
end

local function nearest_build_root(path)
  return root_with_markers(path, { "BUILD.bazel", "BUILD" })
end

local function nearest_jvm_build_root(path)
  return root_with_markers(path, { "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle" })
end

local function is_bazel_project_root(root_dir)
  local workspace_root = bazel_workspace(root_dir)
  if not workspace_root then
    return false
  end

  local normalized_root = normalize(root_dir)
  if normalized_root == normalize(workspace_root) then
    return true
  end

  local build_root = nearest_build_root(root_dir)
  return build_root ~= nil and normalize(build_root) == normalized_root
end

local function java_root_dir(bufname)
  local path = bufname ~= "" and bufname or vim.api.nvim_buf_get_name(0)
  local jvm_root = nearest_jvm_build_root(path)
  local workspace_root = bazel_workspace(path)

  if workspace_root and vim.fn.filereadable(workspace_root .. "/.bazelproject") == 1 then
    if jvm_root and #normalize(jvm_root) > #normalize(workspace_root) then
      return jvm_root
    end
    return workspace_root
  end

  return nearest_build_root(path) or jvm_root or root_with_markers(path, { ".git" })
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

local function append_missing_lines(path, lines)
  local existing = {}
  local ok, current = pcall(vim.fn.readfile, path)
  if ok then
    existing = current
  end

  local seen = {}
  for _, line in ipairs(existing) do
    seen[line] = true
  end

  local changed = false
  for _, line in ipairs(lines) do
    if not seen[line] then
      table.insert(existing, line)
      changed = true
    end
  end

  if changed then
    vim.fn.writefile(existing, path)
  end
end

local function ensure_local_git_excludes(root_dir)
  local exclude_path = root_dir .. "/.git/info/exclude"
  if vim.fn.filereadable(exclude_path) == 0 then
    return
  end

  append_missing_lines(exclude_path, {
    ".classpath",
    ".project",
    ".settings/",
    ".jdtls-bin/",
  })
end

local function delete_if_exists(path)
  if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
    vim.fn.delete(path, "rf")
  end
end

local function remove_stale_nested_eclipse_files(root_dir, source_path)
  local package_dir = nearest_build_root(source_path)
  if not package_dir then
    return
  end

  local normalized_root = normalize(root_dir)
  local normalized_package = normalize(package_dir)
  if normalized_package == normalized_root or not starts_with_path(normalized_package, normalized_root) then
    return
  end

  for _, rel in ipairs({ ".classpath", ".project", ".factorypath", ".settings", ".jdtls-bin" }) do
    delete_if_exists(package_dir .. "/" .. rel)
  end
end

local function xml_escape(value)
  local escaped = tostring(value)
  :gsub("&", "&amp;")
  :gsub('"', "&quot;")
  :gsub("<", "&lt;")
  :gsub(">", "&gt;")
  return escaped
end

local function bazel_ignored_prefixes(root_dir)
  local ok, lines = pcall(vim.fn.readfile, root_dir .. "/.bazelignore")
  if not ok then
    return {}
  end

  local prefixes = {}
  for _, line in ipairs(lines) do
    local without_comment = line:gsub("%s+#.*$", "")
    local trimmed = vim.trim(without_comment)
    if trimmed ~= "" and not trimmed:match("^#") then
      local prefix = trimmed:gsub("/$", "")
      table.insert(prefixes, prefix)
    end
  end
  return prefixes
end

local function is_bazel_ignored(rel, ignored_prefixes)
  if rel:match("^bazel%-") or rel:match("/bazel%-") or rel:match("^%.git/") then
    return true
  end

  for _, prefix in ipairs(ignored_prefixes) do
    if rel == prefix or rel:sub(1, #prefix + 1) == prefix .. "/" then
      return true
    end
  end

  return false
end

local function is_logs_backend_root(root_dir)
  local is_logs_backend = vim.fn.fnamemodify(root_dir, ":t") == "logs-backend"
  local has_streaming_domain = vim.fn.isdirectory(root_dir .. "/domains/streaming") == 1
  return is_logs_backend and has_streaming_domain
end

local function source_search_roots(root_dir)
  if not is_logs_backend_root(root_dir) then
    return { root_dir }
  end

  local roots = {}
  for _, rel in ipairs(logs_backend_source_root_whitelist) do
    local absolute = root_dir .. "/" .. rel
    if vim.fn.isdirectory(absolute) == 1 then
      table.insert(roots, absolute)
    end
  end

  return roots
end

local function discover_source_dirs(root_dir)
  local cached = source_dirs_cache[root_dir]
  if cached then
    return cached
  end

  local source_dirs = {}
  local ignored_prefixes = bazel_ignored_prefixes(root_dir)
  local fd_cmd = { "fd", "-p", "-t", "d", "src/(main|test|benchmark)/java$" }
  vim.list_extend(fd_cmd, source_search_roots(root_dir))
  local lines = vim.fn.systemlist(fd_cmd)

  if vim.v.shell_error == 0 then
    for _, line in ipairs(lines) do
      local absolute = normalize(vim.trim(line))
      if starts_with_path(absolute, normalize(root_dir)) then
        local rel = absolute:sub(#normalize(root_dir) + 2)
        if rel ~= "" and not is_bazel_ignored(rel, ignored_prefixes) then
          table.insert(source_dirs, rel)
        end
      end
    end
  end

  for _, rel in ipairs({ "src/main/java", "src/test/java", "src/benchmark/java" }) do
    if vim.fn.isdirectory(root_dir .. "/" .. rel) == 1 then
      table.insert(source_dirs, rel)
    end
  end

  source_dirs = vim.fn.uniq(vim.fn.sort(source_dirs))
  source_dirs_cache[root_dir] = source_dirs
  return source_dirs
end

local function write_eclipse_settings(root_dir)
  vim.fn.mkdir(root_dir .. "/.settings", "p")
  return write_if_changed(root_dir .. "/.settings/org.eclipse.jdt.core.prefs", {
    "eclipse.preferences.version=1",
    "org.eclipse.jdt.core.compiler.codegen.targetPlatform=25",
    "org.eclipse.jdt.core.compiler.compliance=25",
    "org.eclipse.jdt.core.compiler.problem.enablePreviewFeatures=disabled",
    "org.eclipse.jdt.core.compiler.release=enabled",
    "org.eclipse.jdt.core.compiler.source=25",
  })
end

local function sourcepath_for_jar(root_dir, jar)
  local package_dir = jar:match("/bazel%-bin/(.+)/lib[^/]+%.jar$")
  if not package_dir then
    package_dir = jar:match("/bazel%-out/[^/]+/bin/(.+)/lib[^/]+%.jar$")
  end
  if not package_dir then
    return nil
  end

  local candidate_sources = {
    package_dir .. "/src/main/java",
    package_dir .. "/src/test/java",
    package_dir .. "/src/benchmark/java",
  }

  for _, rel in ipairs(candidate_sources) do
    if vim.fn.isdirectory(root_dir .. "/" .. rel) == 1 then
      return root_dir .. "/" .. rel
    end
  end

  return nil
end

local function lib_classpath_entry(root_dir, jar)
  local sourcepath = sourcepath_for_jar(root_dir, jar)
  if sourcepath then
    return '  <classpathentry kind="lib" path="'
    .. xml_escape(jar)
    .. '" sourcepath="'
    .. xml_escape(sourcepath)
    .. '"/>'
  end

  return '  <classpathentry kind="lib" path="' .. xml_escape(jar) .. '"/>'
end

local function write_eclipse_files(root_dir, jars)
  ensure_local_git_excludes(root_dir)

  local project_name = vim.fn.fnamemodify(root_dir, ":t")
  local project_changed = write_if_changed(root_dir .. "/.project", {
    '<?xml version="1.0" encoding="UTF-8"?>',
    "<projectDescription>",
    "  <name>" .. xml_escape(project_name) .. "</name>",
    "  <comment></comment>",
    "  <projects>",
    "  </projects>",
    "  <buildSpec>",
    "    <buildCommand>",
    "      <name>org.eclipse.jdt.core.javabuilder</name>",
    "      <arguments>",
    "      </arguments>",
    "    </buildCommand>",
    "  </buildSpec>",
    "  <natures>",
    "    <nature>org.eclipse.jdt.core.javanature</nature>",
    "  </natures>",
    "  <filteredResources>",
    "    <filter>",
    "      <id>1</id>",
    "      <name></name>",
    "      <type>30</type>",
    "      <matcher>",
    "        <id>org.eclipse.core.resources.regexFilterMatcher</id>",
    "        <arguments>node_modules|\\.git|bazel-.*|intellij-plugins|__CREATED_BY_JAVA_LANGUAGE_SERVER__</arguments>",
    "      </matcher>",
    "    </filter>",
    "  </filteredResources>",
    "</projectDescription>",
  })

  local cp = { '<?xml version="1.0" encoding="UTF-8"?>', "<classpath>" }
  for _, rel in ipairs(discover_source_dirs(root_dir)) do
    table.insert(cp, '  <classpathentry kind="src" path="' .. xml_escape(rel) .. '"/>')
  end
  table.insert(
    cp,
    '  <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER/org.eclipse.jdt.internal.debug.ui.launcher.StandardVMType/JavaSE-25"/>'
  )
  for _, jar in ipairs(jars or {}) do
    table.insert(cp, lib_classpath_entry(root_dir, jar))
  end
  table.insert(cp, '  <classpathentry kind="output" path=".jdtls-bin"/>')
  table.insert(cp, "</classpath>")

  local classpath_changed = write_if_changed(root_dir .. "/.classpath", cp)
  local settings_changed = write_eclipse_settings(root_dir)
  return project_changed or classpath_changed or settings_changed
end

local function project_file_needs_bootstrap(root_dir)
  local ok, lines = pcall(vim.fn.readfile, root_dir .. "/.project")
  if not ok then
    return true
  end

  local content = table.concat(lines, "\n")
  return content:match("org%.eclipse%.jdt%.core%.javanature") == nil
  or content:match("bazel%-") == nil
  or content:match("intellij%-plugins") == nil
end

local function needs_eclipse_bootstrap(root_dir)
  if vim.fn.filereadable(root_dir .. "/.settings/org.eclipse.jdt.core.prefs") == 0 then
    return true
  end

  if project_file_needs_bootstrap(root_dir) then
    return true
  end

  local ok, lines = pcall(vim.fn.readfile, root_dir .. "/.classpath")
  if not ok then
    return true
  end

  local expected_sources = {}
  local seen_sources = {}
  if is_logs_backend_root(root_dir) then
    for _, rel in ipairs(discover_source_dirs(root_dir)) do
      expected_sources[rel] = true
    end
  end

  local has_source_entry = false
  local has_java_25_runtime = false
  for _, line in ipairs(lines) do
    local source = line:match('kind="src"%s+path="([^"]+)"')
    if source then
      has_source_entry = true
      seen_sources[source] = true
      if is_logs_backend_root(root_dir) and not expected_sources[source] then
        return true
      end
    end

    has_java_25_runtime = has_java_25_runtime or line:match("JavaSE%-25") ~= nil
    local jar = line:match('kind="lib"%s+path="([^"]+)"')
    if jar and sourcepath_for_jar(root_dir, jar) and not line:match('sourcepath="') then
      return true
    end
  end

  if is_logs_backend_root(root_dir) then
    for source in pairs(expected_sources) do
      if not seen_sources[source] then
        return true
      end
    end
  end

  return not (has_source_entry and has_java_25_runtime)
end

local function existing_classpath_jars(root_dir)
  local ok, lines = pcall(vim.fn.readfile, root_dir .. "/.classpath")
  if not ok then
    return {}
  end

  local jars = {}
  for _, line in ipairs(lines) do
    local jar = line:match('kind="lib"%s+path="([^"]+)"')
    if jar then
      table.insert(jars, jar)
    end
  end
  return jars
end

local function bazel_build_flags(workspace_root)
  local ok, lines = pcall(vim.fn.readfile, workspace_root .. "/.bazelproject")
  if not ok then
    return {}
  end

  local flags = {}
  local in_build_flags = false
  for _, line in ipairs(lines) do
    if line:match("^build_flags:%s*$") then
      in_build_flags = true
    elseif line:match("^%S") then
      in_build_flags = false
    elseif in_build_flags then
      local flag = vim.trim(line)
      if flag ~= "" and not flag:match("^#") then
        table.insert(flags, flag)
      end
    end
  end
  return flags
end

local function bzl_cmd(workspace_root, command, args)
  local cmd = { "bzl", command }
  if command == "build" or command == "cquery" then
    vim.list_extend(cmd, bazel_build_flags(workspace_root))
  end
  vim.list_extend(cmd, args)
  return cmd
end

local function bazel_execution_root(workspace_root)
  local link = workspace_root .. "/bazel-" .. vim.fn.fnamemodify(workspace_root, ":t")
  return vim.uv.fs_realpath(link) or link
end

local function resolve_bazel_path(workspace_root, raw_path)
  local execution_root = bazel_execution_root(workspace_root)
  local candidates = {}

  if vim.startswith(raw_path, "/") then
    table.insert(candidates, raw_path)
  else
    table.insert(candidates, workspace_root .. "/" .. raw_path)
    table.insert(candidates, execution_root .. "/" .. raw_path)
    table.insert(candidates, workspace_root .. "/bazel-bin/" .. raw_path)

    if vim.startswith(raw_path, "../") then
      local external_path = raw_path:sub(4)
      table.insert(candidates, execution_root .. "/external/" .. external_path)
      table.insert(candidates, workspace_root .. "/bazel-bin/external/" .. external_path)
    end
  end

  for _, candidate in ipairs(candidates) do
    local normalized = normalize(candidate)
    if vim.fn.filereadable(normalized) == 1 then
      return normalized
    end
  end
  return nil
end

local function merge_unique(first, second)
  local merged = {}
  local seen = {}

  for _, list in ipairs({ first or {}, second or {} }) do
    for _, value in ipairs(list) do
      if value ~= "" and not seen[value] then
        table.insert(merged, value)
        seen[value] = true
      end
    end
  end

  return merged
end

local function bazel_package_label(workspace_root, package_dir)
  local rel = package_dir:sub(#workspace_root + 2)
  if rel == "" then
    return "//"
  end
  return "//" .. rel
end

local function pick_bazel_target(lines, source_path)
  local labels = {}
  for _, line in ipairs(lines) do
    local kind, label = line:match("^(.-)%s+rule%s+(%S+)$")
    if kind and label and not kind:match("^_") and not label:match("%.classpath$") then
      table.insert(labels, { kind = kind, label = label })
    end
  end

  local function pick(pred)
    for _, item in ipairs(labels) do
      if pred(item.kind, item.label) then
        return item.label
      end
    end
  end

  local is_test = source_path:match("/src/test/java/") ~= nil
  local is_benchmark = source_path:match("/src/benchmark/java/") ~= nil

  if is_test then
    return pick(function(kind, label)
      return kind:match("java") and (kind:match("test") or label:match("[_-]tests?$"))
    end)
    or pick(function(kind) return kind:match("java_library$") end)
    or pick(function(kind) return kind:match("java") ~= nil end)
  end

  if is_benchmark then
    return pick(function(kind, label)
      return kind:match("java") and (kind:match("jmh") or label:match("benchmark"))
    end)
    or pick(function(kind) return kind:match("java_library$") end)
    or pick(function(kind) return kind:match("java") ~= nil end)
  end

  return pick(function(kind) return kind:match("java_library$") end)
  or pick(function(kind) return kind:match("java") ~= nil end)
end

local function read_repo_classpath_async(workspace_root, target, on_done)
  local classpath_target = target .. ".classpath"
  vim.system(bzl_cmd(workspace_root, "build", { classpath_target }), { cwd = workspace_root }, function(build_r)
    if build_r.code ~= 0 then
      vim.schedule(function() on_done({}) end)
      return
    end

    vim.system(
      bzl_cmd(workspace_root, "cquery", { "--output=files", classpath_target }),
      { cwd = workspace_root },
      function(cquery_r)
        if cquery_r.code ~= 0 then
          vim.schedule(function() on_done({}) end)
          return
        end

        vim.schedule(function()
          local classpath_file
          for _, line in ipairs(vim.split(cquery_r.stdout or "", "\n", { plain = true })) do
            if line:match("%.classpath$") then
              classpath_file = resolve_bazel_path(workspace_root, line)
              break
            end
          end

          if not classpath_file then
            on_done({})
            return
          end

          local ok, entries = pcall(vim.fn.readfile, classpath_file)
          if not ok then
            on_done({})
            return
          end

          local jars = {}
          for _, entry in ipairs(entries) do
            local jar = resolve_bazel_path(workspace_root, vim.trim(entry))
            if jar then
              table.insert(jars, jar)
            end
          end
          on_done(jars)
        end)
      end
    )
  end)
end

local function read_javainfo_classpath_async(workspace_root, target, on_done)
  vim.system(
    bzl_cmd(workspace_root, "cquery", {
      "--output=starlark",
      '--starlark:expr="\\n".join([f.path for f in target[JavaInfo].transitive_compile_time_jars.to_list()])',
      target,
    }),
    { cwd = workspace_root },
    function(cquery_r)
      vim.schedule(function()
        if cquery_r.code ~= 0 then
          on_done({})
          return
        end

        local jars = {}
        for _, line in ipairs(vim.split(cquery_r.stdout or "", "\n", { plain = true })) do
          local jar = resolve_bazel_path(workspace_root, vim.trim(line))
          if jar then
            table.insert(jars, jar)
          end
        end
        on_done(jars)
      end)
    end
  )
end

local function finish_refresh(on_done, changed)
  vim.schedule(function() on_done(changed) end)
end

local function refresh_bazel_classpath_async(root_dir, source_path, on_done)
  local workspace_root = bazel_workspace(root_dir)
  if not workspace_root then
    finish_refresh(on_done, false)
    return
  end

  local package_dir = nearest_build_root(source_path)
  if not package_dir or not starts_with_path(normalize(package_dir), normalize(workspace_root)) then
    finish_refresh(on_done, false)
    return
  end

  local package_label = bazel_package_label(workspace_root, package_dir)
  local job_key = root_dir .. ":" .. package_label
  if refresh_jobs[job_key] then
    finish_refresh(on_done, false)
    return
  end
  refresh_jobs[job_key] = true

  local function finish(changed)
    refresh_jobs[job_key] = nil
    finish_refresh(on_done, changed)
  end

  vim.system(
    { "bzl", "query", package_label .. ":all", "--output=label_kind" },
    { cwd = workspace_root },
    function(query_r)
      if query_r.code ~= 0 then
        finish(false)
        return
      end

      local target = pick_bazel_target(vim.split(query_r.stdout or "", "\n", { plain = true }), normalize(source_path))
      if not target then
        finish(false)
        return
      end

      vim.system(bzl_cmd(workspace_root, "build", { target }), { cwd = workspace_root }, function(build_r)
        if build_r.code ~= 0 then
          finish(false)
          return
        end

        read_repo_classpath_async(workspace_root, target, function(repo_jars)
          read_javainfo_classpath_async(workspace_root, target, function(javainfo_jars)
            local jars = merge_unique(repo_jars, javainfo_jars)
            if #jars == 0 then
              finish(false)
              return
            end

            local changed = write_eclipse_files(root_dir, jars)
            finish(changed)
          end)
        end)
      end)
    end
  )
end

local function bazel_remote_jdk_25(root_dir)
  local workspace_root = bazel_workspace(root_dir)
  if not workspace_root then
    return nil
  end

  local execroot = bazel_execution_root(workspace_root)
  for _, candidate in ipairs(vim.fn.glob(execroot .. "/external/remote_jdk25_*", false, true)) do
    if vim.fn.executable(candidate .. "/bin/java") == 1 then
      return candidate
    end
  end
  return nil
end

local function jdtls_init_options()
  local init_options = { bundles = {} }
  local ok, capabilities = pcall(require, "jdtls.capabilities")
  if ok then
    init_options.extendedClientCapabilities = capabilities
  end
  return init_options
end

local function jdtls_settings(root_dir)
  local java = {
    configuration = {
      updateBuildConfiguration = "disabled",
    },
  }
  local jdk_25 = bazel_remote_jdk_25(root_dir)

  if jdk_25 then
    java.configuration.runtimes = {
      {
        name = "JavaSE-25",
        path = jdk_25,
        default = true,
      },
    }
  end

  if is_bazel_project_root(root_dir) then
    java.import = {
      exclusions = {
        "**/.jdtls-bin/**",
        "**/bazel-*/**",
        "**/bazel-bin/**",
        "**/bazel-out/**",
        "**/bazel-testlogs/**",
        "**/external/**",
        "**/intellij-plugins/**",
      },
      gradle = { enabled = false },
      maven = { enabled = false },
    }
    java.project = {
      resourceFilters = {
        ".git",
        ".jdtls-bin",
        "bazel-*",
        "bazel-bin",
        "bazel-out",
        "bazel-testlogs",
        "external",
        "intellij-plugins",
      },
    }
  end

  return { java = java }
end

local function jdtls_config(root_dir)
  local project_name = root_dir:gsub("[/\\]", "-")
  return {
    cmd = { "jdtls", "-data", vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. project_name },
    root_dir = root_dir,
    on_attach = on_attach,
    settings = jdtls_settings(root_dir),
    init_options = jdtls_init_options(),
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

local function stop_stale_nested_jdtls_clients(root_dir, source_path)
  local normalized_root = normalize(root_dir)
  local normalized_source = normalize(source_path)

  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    local client_root = client.config and client.config.root_dir
    if client_root then
      local normalized_client_root = normalize(client_root)
      local is_nested_client = (
        normalized_client_root ~= normalized_root
        and starts_with_path(normalized_source, normalized_client_root)
        and starts_with_path(normalized_client_root, normalized_root)
      )

      if is_nested_client then
        client:stop()
      end
    end
  end
end

pcall(vim.api.nvim_buf_del_user_command, 0, "JdtlsRefreshClasspath")
vim.api.nvim_buf_create_user_command(0, "JdtlsRefreshClasspath", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  local root = java_root_dir(bufname)
  if not root then
    return
  end

  vim.notify("[jdtls] Refreshing Bazel classpath...", vim.log.levels.INFO)
  if not is_bazel_project_root(root) then
    vim.notify("[jdtls] Current Java root is not a Bazel project.", vim.log.levels.INFO)
    return
  end

  refresh_bazel_classpath_async(root, bufname, function(changed)
    if changed then
      vim.notify("[jdtls] Classpath updated, restarting...", vim.log.levels.INFO)
      restart_jdtls(jdtls_config(root))
    else
      vim.notify("[jdtls] Classpath unchanged.", vim.log.levels.INFO)
    end
  end)
end, {})

local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return
end

local bufname = vim.api.nvim_buf_get_name(0)
local root = java_root_dir(bufname)
if not root then
  return
end

if is_bazel_project_root(root) then
  remove_stale_nested_eclipse_files(root, bufname)
  stop_stale_nested_jdtls_clients(root, bufname)

  if needs_eclipse_bootstrap(root) then
    write_eclipse_files(root, existing_classpath_jars(root))
  end
end

jdtls.start_or_attach(jdtls_config(root))
