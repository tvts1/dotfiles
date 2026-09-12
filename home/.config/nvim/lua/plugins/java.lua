-- Resolve asdf no diretório relevante, sem executar um shell interativo.
local function asdf_java(directory)
  if vim.fn.executable("asdf") ~= 1 then
    return nil
  end
  local result = vim.system({ "asdf", "where", "java" }, { cwd = directory, text = true }):wait()
  local home = result.code == 0 and vim.trim(result.stdout) or nil
  return home and vim.fn.executable(home .. "/bin/java") == 1 and home or nil
end

local function java_major(java_home)
  if not java_home or java_home == "" or vim.fn.executable(java_home .. "/bin/java") ~= 1 then
    return nil
  end

  local ok, release = pcall(vim.fn.readfile, java_home .. "/release")
  if not ok then
    return nil
  end

  return tonumber(table.concat(release, "\n"):match('JAVA_VERSION="(%d+)'))
end

local function jdtls_java()
  local configured = vim.env.JDTLS_JAVA_HOME
  local java_home = configured and configured ~= "" and configured or asdf_java(vim.env.HOME)
  local major = java_major(java_home)

  if major and major >= 21 then
    return java_home
  end

  local source = configured and configured ~= "" and "JDTLS_JAVA_HOME" or "Java padrão da HOME no asdf"
  vim.notify(source .. " precisa apontar para um JDK 21 ou superior", vim.log.levels.ERROR)
  return nil
end

local function project_root()
  local root = vim.fs.root(0, {
    "mvnw",
    "gradlew",
    "pom.xml",
    "settings.gradle",
    "settings.gradle.kts",
    "build.gradle",
    "build.gradle.kts",
    ".git",
  })

  return root or LazyVim.root.get()
end

local function executable(root, wrapper, fallback)
  local path = root .. "/" .. wrapper
  return vim.fn.executable(path) == 1 and ("./" .. wrapper) or fallback
end

local function build_command(task, profile)
  local root = project_root()
  local has_maven = vim.uv.fs_stat(root .. "/pom.xml") ~= nil or vim.uv.fs_stat(root .. "/mvnw") ~= nil
  local has_gradle = vim.uv.fs_stat(root .. "/build.gradle") ~= nil
    or vim.uv.fs_stat(root .. "/build.gradle.kts") ~= nil
    or vim.uv.fs_stat(root .. "/gradlew") ~= nil

  if has_maven then
    local commands = {
      run = { executable(root, "mvnw", "mvn"), "spring-boot:run" },
      test = { executable(root, "mvnw", "mvn"), "test" },
      build = { executable(root, "mvnw", "mvn"), "package" },
      clean = { executable(root, "mvnw", "mvn"), "clean" },
    }
    if profile and profile ~= "" and task == "run" then
      table.insert(commands.run, "-Dspring-boot.run.profiles=" .. profile)
    end
    return commands[task], root
  end

  if has_gradle then
    local commands = {
      run = { executable(root, "gradlew", "gradle"), "bootRun" },
      test = { executable(root, "gradlew", "gradle"), "test" },
      build = { executable(root, "gradlew", "gradle"), "build" },
      clean = { executable(root, "gradlew", "gradle"), "clean" },
    }
    if profile and profile ~= "" and task == "run" then
      table.insert(commands.run, "--args=--spring.profiles.active=" .. profile)
    end
    return commands[task], root
  end

  LazyVim.warn("No pom.xml or Gradle build found", { title = "Java" })
end

local function run_task(task, profile)
  local command, root = build_command(task, profile)
  if command then
    Snacks.terminal(command, {
      cwd = root,
      env = { JAVA_HOME = asdf_java(root) or vim.env.JAVA_HOME },
      win = { position = "bottom", height = 0.4 },
    })
  end
end

local function run_with_profile()
  vim.ui.input({ prompt = "Spring profile: " }, function(profile)
    if profile then
      run_task("run", profile)
    end
  end)
end

local java_settings = {
  java = {
    autobuild = { enabled = true },
    cleanup = { actionsOnSave = { "qualifyMembers", "addOverride", "addDeprecated" } },
    completion = {
      favoriteStaticMembers = {
        "org.assertj.core.api.Assertions.*",
        "org.junit.jupiter.api.Assertions.*",
        "org.mockito.ArgumentMatchers.*",
        "org.mockito.Mockito.*",
        "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
        "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
      },
      filteredTypes = {
        "com.sun.*",
        "io.micrometer.shaded.*",
        "java.awt.*",
        "jdk.*",
        "sun.*",
      },
      guessMethodArguments = true,
      importOrder = { "java", "javax", "jakarta", "org", "com" },
    },
    configuration = { updateBuildConfiguration = "interactive" },
    eclipse = { downloadSources = true },
    format = { enabled = true },
    implementationsCodeLens = { enabled = true },
    inlayHints = { parameterNames = { enabled = "all" } },
    maven = { downloadSources = true },
    references = { includeDecompiledSources = true },
    referencesCodeLens = { enabled = true },
    saveActions = { organizeImports = true },
    signatureHelp = { enabled = true },
    sources = {
      organizeImports = {
        starThreshold = 9999,
        staticStarThreshold = 9999,
      },
    },
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "xml" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lemminx = {},
      },
    },
  },

  {
    "mfussenegger/nvim-jdtls",
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = {
          ensure_installed = { "vscode-spring-boot-tools" },
        },
      },
    },
    opts = function(_, opts)
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, java_settings)

      -- O launcher JDTLS exige Java >= 21. Usa o padrão da HOME, enquanto
      -- Maven/Gradle e os projetos continuam selecionando seu próprio JDK.
      local server_home = jdtls_java()
      if server_home then
        table.insert(opts.cmd, "--java-executable=" .. server_home .. "/bin/java")
      end

      -- The Spring Tools package exposes JDTLS extensions. Appending them here
      -- keeps the Java debugger and test bundles configured by LazyVim intact.
      local previous_jdtls = opts.jdtls
      opts.jdtls = function(config)
        if type(previous_jdtls) == "function" then
          config = previous_jdtls(config) or config
        elseif type(previous_jdtls) == "table" then
          config = vim.tbl_deep_extend("force", config, previous_jdtls)
        end

        local project_home = asdf_java(config.root_dir or project_root())
        if project_home then
          local major = java_major(project_home)
          if major then
            config.settings = config.settings or {}
            config.settings.java = config.settings.java or {}
            config.settings.java.configuration = config.settings.java.configuration or {}
            config.settings.java.configuration.runtimes = {
              { name = "JavaSE-" .. major, path = project_home, default = true },
            }
          end
        end

        config.init_options = config.init_options or {}
        config.init_options.bundles = config.init_options.bundles or {}
        local mason = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
        local spring_jars = vim.fn.glob(mason .. "/share/vscode-spring-boot-tools/jdtls/*.jar", false, true)
        vim.list_extend(config.init_options.bundles, spring_jars)
        return config
      end

      local previous_on_attach = opts.on_attach
      opts.on_attach = function(args)
        if previous_on_attach then
          previous_on_attach(args)
        end

        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
        end

        map("<leader>j", "<nop>", "+java")
        map("<leader>jr", function()
          run_task("run")
        end, "Spring Boot Run")
        map("<leader>jR", run_with_profile, "Spring Boot Run (Profile)")
        map("<leader>jt", function()
          run_task("test")
        end, "Project Tests")
        map("<leader>jb", function()
          run_task("build")
        end, "Project Build")
        map("<leader>jc", function()
          run_task("clean")
        end, "Project Clean")
        map("<leader>ju", "<cmd>JdtUpdateConfig<cr>", "Refresh Project")
        map("<leader>jo", require("jdtls").organize_imports, "Organize Imports")
      end

      return opts
    end,
  },

  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<F5>",
        function()
          require("dap").continue()
        end,
        desc = "Debug: Run/Continue",
      },
      {
        "<F9>",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Debug: Toggle Breakpoint",
      },
      {
        "<F10>",
        function()
          require("dap").step_over()
        end,
        desc = "Debug: Step Over",
      },
      {
        "<F11>",
        function()
          require("dap").step_into()
        end,
        desc = "Debug: Step Into",
      },
      {
        "<S-F11>",
        function()
          require("dap").step_out()
        end,
        desc = "Debug: Step Out",
      },
    },
  },
}
