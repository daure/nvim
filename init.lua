vim.g.mapleader = " "
vim.opt.shell = "pwsh"
vim.opt.shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command"
vim.opt.shellquote = ""
vim.opt.shellxquote = ""

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.fileformats = "unix,dos"
vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize"
vim.opt.colorcolumn = ""
vim.opt.laststatus = 3
vim.opt.fillchars:append({ eob = " ", vert = " " })

vim.lsp.config.cssls = {
  settings = {
    css = { lint = { unknownAtRules = "ignore" } },
    scss = { lint = { unknownAtRules = "ignore" } },
    less = { lint = { unknownAtRules = "ignore" } },
  },
}

-- Neovide
vim.g.neovide_fullscreen = true
vim.g.neovide_cursor_animation_length = 0
vim.g.neovide_scroll_animation_length = 0.1
vim.o.guifont = "JetBrainsMono NF:h14"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
  },

  {
    "nvim-tree/nvim-web-devicons",
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 35,
          side = "left",
          preserve_window_proportions = true,
        },
        renderer = {
          group_empty = true,
          root_folder_label = false,
        },
        filters = {
          dotfiles = false,
        },
        update_focused_file = {
          enable = true,
        },
        git = {
          enable = true,
          ignore = false,
          timeout = 400,
        },
        auto_reload_on_write = true,
        filesystem_watchers = {
          enable = true,
          ignore_dirs = {
            "node_modules",
            "build",
            "dist",
            ".nuxt",
          },
          max_events = 50000,
        },
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set("n", "<S-h>", ":tabprev<CR>", { buffer = bufnr, nowait = true })
          vim.keymap.set("n", "<S-l>", ":tabnext<CR>", { buffer = bufnr, nowait = true })

          local function smart_open()
            local node = api.tree.get_node_under_cursor()
            if node and node.parent == nil then return end
            api.node.open.edit()
          end
          vim.keymap.set("n", "<CR>", smart_open, { buffer = bufnr, noremap = true, silent = true, nowait = true })
        end,
      })
    end,
  },

  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({
        winopts = {
          preview = {
            layout = "vertical",
            vertical = "down:50%",
          },
        },
        keymap = {
          builtin = {
            ["<C-u>"] = "preview-page-up",
            ["<C-d>"] = "preview-page-down",
          },
        },
       files = {
         fzf_opts = { ["--scheme"] = "path" },
       },
        buffers = {
          no_term_buffers = true,
        },
      })
    end,
  },

  {
    "rmagatti/auto-session",
    enabled = false,
    config = function()
      require("auto-session").setup({
        suppressed_dirs = { "~/", "~/Downloads", "/" },
        pre_save_cmds = { "NvimTreeClose" },
        post_restore_cmds = { "NvimTreeOpen" },
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate'
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        current_line_blame_opts = {
          delay = 0,
        },
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr })
          vim.keymap.set("n", "<leader>gt", gs.toggle_current_line_blame, { buffer = bufnr })
          vim.keymap.set("n", "]c", gs.next_hunk, { buffer = bufnr })
          vim.keymap.set("n", "[c", gs.prev_hunk, { buffer = bufnr })
        end,
      })
    end,
  },

  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ensure_installed = { "prettier" },
      })
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "angularls", "html", "cssls", "tailwindcss", "vue_ls" },
      })

      -- Volar v3: wire ts_ls as the TypeScript backend for vue_ls
      local vue_ls_path = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      local vue_plugin = {
        name = "@vue/typescript-plugin",
        location = vue_ls_path,
        languages = { "vue" },
        configNamespace = "typescript",
      }
      vim.lsp.config("ts_ls", {
        init_options = { plugins = { vue_plugin } },
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      })
      vim.lsp.config("vue_ls", {
        on_init = function(client)
          client.handlers["tsserver/request"] = function(_, result, context)
            local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })
            if #clients == 0 then return end
            local id, command, payload = unpack(unpack(result))
            clients[1]:exec_cmd(
              { title = "vue_ls_forward", command = "typescript.tsserverRequest", arguments = { command, payload } },
              { bufnr = context.bufnr },
              function(_, r)
                client:notify("tsserver/response", { { id, r and r.body } })
              end
            )
          end
        end,
      })

      vim.lsp.enable("lua_ls")
      vim.lsp.enable("pyright")
      vim.lsp.enable("ts_ls")
      vim.lsp.enable("angularls")
      vim.lsp.enable("html")
      vim.lsp.enable("cssls")
      vim.lsp.enable("tailwindcss")
      vim.lsp.enable("vue_ls")
    end,
  },

  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lspsaga").setup({
        lightbulb = {
          enable = false,
        },
      })
    end,
  },

{
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        completion = {
          autocomplete = { "TextChanged" },
        },
        formatting = {
          format = require("lspkind").cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          html = { "prettier" },
          htmlangular = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          json = { "prettier" },
          markdown = { "prettier" },
        },
        format_on_save = function(bufnr)
          -- use project prettier if available, fall back to Mason's
          local project_prettier = vim.fn.findfile("node_modules/.bin/prettier", vim.fn.getcwd() .. ";")
          if project_prettier ~= "" or vim.fn.executable("prettier") == 1 then
            return { timeout_ms = 2000, lsp_fallback = false }
          end
        end,
      })
    end,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup()
    end,
  },

  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("diffview").setup()
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = "cd app && npm install",
  },

  {
    "numToStr/Comment.nvim",
    opts = {},
    config = function(_, opts)
      require("Comment").setup(opts)
      local api = require("Comment.api")

      -- Normal mode: toggle current line
      vim.keymap.set("n", "<C-/>", api.toggle.linewise.current, { desc = "Comment toggle line" })
      vim.keymap.set("n", "<C-_>", api.toggle.linewise.current, { desc = "Comment toggle line" })

      -- Visual mode: toggle selection
      local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
      vim.keymap.set("v", "<C-/>", function()
        vim.api.nvim_feedkeys(esc, "nx", false)
        api.toggle.linewise(vim.fn.visualmode())
      end, { desc = "Comment toggle selection" })
      vim.keymap.set("v", "<C-_>", function()
        vim.api.nvim_feedkeys(esc, "nx", false)
        api.toggle.linewise(vim.fn.visualmode())
      end, { desc = "Comment toggle selection" })
    end,
  },

})

vim.cmd.colorscheme("tokyonight")

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    require("nvim-tree.api").tree.open()
  end,
})

function _G.custom_tabline()
  local s = ""
  for i = 1, vim.fn.tabpagenr("$") do
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = vim.fn.tabpagebuflist(i)[winnr]
    local bufname = vim.fn.bufname(bufnr)
    local modified = vim.fn.getbufvar(bufnr, "&mod") == 1

    s = s .. "%" .. i .. "T"
    s = s .. (i == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#")

    local name
    if i == 1 then
      local tab_cwd = vim.fn.getcwd(-1, i)
      name = vim.fn.fnamemodify(tab_cwd, ":t")
      if name == "" then
        name = tab_cwd
      end
      name = "📁 " .. name
    elseif bufname:match("term://") then
      name = bufname:match("//[^:]+:(.+)$") or "terminal"
      name = name:match("([^/\\]+)$") or name
      name = name:gsub("%.exe$", ""):gsub("%.cmd$", "")
      if name:lower():match("opencode") then name = "󱙺 OpenCode"
      elseif name:lower():match("lazygit") then name = " LazyGit"
      elseif name:lower():match("pwsh") or name:lower():match("powershell") then name = " PowerShell"
      end
    elseif bufname == "" then
      name = "new"
    else
      name = vim.fn.fnamemodify(bufname, ":t")
    end

    s = s .. " " .. (modified and "● " or "") .. name .. " "
  end
  return s .. "%#TabLineFill#%T"
end

vim.opt.tabline = "%!v:lua.custom_tabline()"
vim.opt.showtabline = 2

local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<C-e>", fzf.buffers)
vim.keymap.set("n", "<leader>fh", fzf.help_tags, { desc = "Help tags" })
vim.keymap.set("n", "<leader>fk", fzf.keymaps, { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>gs", fzf.git_status, { desc = "Git status" })
vim.keymap.set("n", "<leader>gb", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "gitsigns-blame" then
      vim.api.nvim_win_close(win, true)
      return
    end
  end
  require("gitsigns").blame()
end, { desc = "Git blame toggle" })

vim.keymap.set("n", "<leader>dv", ":DiffviewOpen<CR>", { desc = "Diff view open" })
vim.keymap.set("n", "<leader>dh", ":DiffviewFileHistory %<CR>", { desc = "Diff file history" })
vim.keymap.set("n", "<leader>mp", ":MarkdownPreviewToggle<CR>", { desc = "Markdown preview toggle" })

vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { silent = true, desc = "Go to definition" })
vim.keymap.set("n", "<C-b>", "<cmd>Lspsaga goto_definition<CR>", { silent = true, desc = "Go to definition" })
vim.keymap.set("n", "gr", fzf.lsp_references, { desc = "Find references" })
vim.keymap.set("n", "<M-F7>", fzf.lsp_references, { desc = "Find references" })
vim.keymap.set("n", "gi", "<cmd>Lspsaga finder imp<CR>", { silent = true, desc = "Find implementations" })
vim.keymap.set("n", "<C-M-b>", "<cmd>Lspsaga finder imp<CR>", { silent = true, desc = "Find implementations" })
vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true, desc = "Hover documentation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { silent = true, desc = "Code actions" })
vim.keymap.set({ "n", "i" }, "<M-CR>", "<cmd>Lspsaga code_action<CR>", { silent = true, desc = "Quick fixes" })
vim.keymap.set("n", "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>", { silent = true, desc = "Show line diagnostics" })
vim.keymap.set("n", "[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { silent = true, desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", { silent = true, desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { silent = true, desc = "Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>xw", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", { silent = true, desc = "Buffer diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>xr", "<cmd>Trouble lsp_references toggle<CR>", { silent = true, desc = "References (Trouble)" })
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<M-l>", ":NvimTreeFindFile<CR>", { desc = "Find file in tree" })

local function close_current_tab()
  local tab = vim.api.nvim_get_current_tabpage()
  local term_bufs = {}

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.bo[bufnr].buftype == "terminal" then
      term_bufs[bufnr] = true
    end
  end

  vim.cmd("tabclose!")

  for bufnr, _ in pairs(term_bufs) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
  end
end

vim.keymap.set("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
vim.keymap.set({"n", "t"}, "<leader>tc", close_current_tab, { desc = "Close tab" })
vim.keymap.set({"n", "t"}, "<C-F4>", close_current_tab, { desc = "Close tab" })
vim.keymap.set("n", "<C-M-q>", ":qa!<CR>", { desc = "Quit all" })
vim.keymap.set("t", "<C-M-q>", "<C-\\><C-n>:qa!<CR>", { silent = true, desc = "Quit all from terminal mode" })
vim.keymap.set({"n", "t"}, "<M-q>", close_current_tab, { desc = "Close tab" })
vim.keymap.set("n", "<leader>to", ":tabonly<CR>", { desc = "Close other tabs" })
vim.keymap.set("n", "<S-l>", ":tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<S-h>", ":tabprev<CR>", { desc = "Previous tab" })
vim.keymap.set({ "n", "i" }, "<C-s>", "<cmd>wall<CR>", { desc = "Save all buffers" })
vim.keymap.set({ "n", "t" }, "<M-c>", function()
  vim.cmd("tabnext 1")
end, { desc = "Go to first tab" })

vim.keymap.set({"n", "i", "t", "v"}, "<F4>", "<CR>")
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { silent = true, desc = "Clear search highlight" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to below window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to above window" })
vim.keymap.set("t", "<M-Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left window" })
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to right window" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to below window" })
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to above window" })
local function get_tab_order_index(target_type)
  local last_normal = 0
  local last_oc = 0
  local last_lg = 0

  for i = 1, vim.fn.tabpagenr("$") do
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local bufname = vim.fn.bufname(bufnr)
    if bufname:match("term://") then
      local name = bufname:lower()
      if name:match("opencode") then
        last_oc = math.max(last_oc, i)
      elseif name:match("lazygit") then
        last_lg = math.max(last_lg, i)
      end
    else
      last_normal = math.max(last_normal, i)
    end
  end

  if target_type == "opencode" then
    return math.max(last_normal, last_oc)
  elseif target_type == "lazygit" then
    return math.max(last_normal, last_oc, last_lg)
  elseif target_type == "powershell" then
    return vim.fn.tabpagenr("$")
  end
  return vim.fn.tabpagenr("$")
end

local function open_ordered_terminal(cmd, term_type)
  local idx = get_tab_order_index(term_type)
  vim.cmd(idx .. "tabnew | terminal " .. (cmd or ""))
  vim.cmd("startinsert")
end

local function find_or_open_terminal(cmd, name)
  for i = 1, vim.fn.tabpagenr("$") do
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = vim.fn.tabpagebuflist(i)[winnr]
    local bufname = vim.fn.bufname(bufnr)
    if bufname:match("term://") and bufname:lower():match(cmd:lower()) then
      vim.cmd(i .. "tabnext")
      vim.cmd("startinsert")
      return
    end
  end
  open_ordered_terminal(cmd, name)
end

vim.keymap.set({"n", "t"}, "<M-C-t>", function()
  open_ordered_terminal("", "powershell")
end)
vim.keymap.set({"n", "t"}, "<M-C-o>", function()
  open_ordered_terminal("opencode", "opencode")
end)

vim.keymap.set({"n", "t"}, "<M-S-o>", function()
  local current = vim.fn.tabpagenr()
  local oc_tabs = {}
  for i = 1, vim.fn.tabpagenr("$") do
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local bufname = vim.fn.bufname(bufnr)
    if bufname:match("term://") and bufname:lower():match("opencode") then
      table.insert(oc_tabs, i)
    end
  end
  if #oc_tabs == 0 then return end
  for i = #oc_tabs, 1, -1 do
    if oc_tabs[i] < current then
      vim.cmd(oc_tabs[i] .. "tabnext")
      vim.cmd("startinsert")
      return
    end
  end
  vim.cmd(oc_tabs[#oc_tabs] .. "tabnext")
  vim.cmd("startinsert")
end)

vim.keymap.set({"n", "t"}, "<M-S-t>", function()
  local current = vim.fn.tabpagenr()
  local ps_tabs = {}
  for i = 1, vim.fn.tabpagenr("$") do
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local bufname = vim.fn.bufname(bufnr)
    if bufname:match("term://") and
       not bufname:lower():match("opencode") and
       not bufname:lower():match("lazygit") then
      table.insert(ps_tabs, i)
    end
  end
  if #ps_tabs == 0 then return end
  for i = #ps_tabs, 1, -1 do
    if ps_tabs[i] < current then
      vim.cmd(ps_tabs[i] .. "tabnext")
      vim.cmd("startinsert")
      return
    end
  end
  vim.cmd(ps_tabs[#ps_tabs] .. "tabnext")
  vim.cmd("startinsert")
end)

vim.keymap.set({"n", "t"}, "<M-o>", function()
  local current = vim.fn.tabpagenr()
  local oc_tabs = {}
  for i = 1, vim.fn.tabpagenr("$") do
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local bufname = vim.fn.bufname(bufnr)
    if bufname:match("term://") and bufname:lower():match("opencode") then
      table.insert(oc_tabs, i)
    end
  end
  if #oc_tabs == 0 then
    open_ordered_terminal("opencode", "opencode")
    return
  end
  for _, i in ipairs(oc_tabs) do
    if i > current then
      vim.cmd(i .. "tabnext")
      vim.cmd("startinsert")
      return
    end
  end
  vim.cmd(oc_tabs[1] .. "tabnext")
  vim.cmd("startinsert")
end)
vim.keymap.set({"n", "t"}, "<M-g>", function()
  find_or_open_terminal("lazygit", "lazygit")
end)
vim.keymap.set({"n", "t"}, "<M-t>", function()
  local current = vim.fn.tabpagenr()
  local ps_tabs = {}
  for i = 1, vim.fn.tabpagenr("$") do
    local bufnr = vim.fn.tabpagebuflist(i)[vim.fn.tabpagewinnr(i)]
    local bufname = vim.fn.bufname(bufnr)
    if bufname:match("term://") and
       not bufname:lower():match("opencode") and
       not bufname:lower():match("lazygit") then
      table.insert(ps_tabs, i)
    end
  end
  if #ps_tabs == 0 then
    open_ordered_terminal("", "powershell")
    return
  end
  for _, i in ipairs(ps_tabs) do
    if i > current then
      vim.cmd(i .. "tabnext")
      vim.cmd("startinsert")
      return
    end
  end
  vim.cmd(ps_tabs[1] .. "tabnext")
  vim.cmd("startinsert")
end)

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  command = "silent! wa",
})

-- Auto-enter insert mode when focusing a terminal buffer
vim.api.nvim_create_autocmd("FocusGained", {
  pattern = "*",
  callback = function()
    vim.schedule(function()
      if vim.bo.buftype == "terminal" and vim.fn.mode() ~= "t" then
        vim.cmd("startinsert")
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.cmd("startinsert")
  end,
})
