-- Highlight, edit, and navigate code.
--
-- Neovim 0.12 dropped compatibility with nvim-treesitter's `master` branch:
-- injection parsing (which `render-markdown` triggers on every markdown buffer)
-- crashes inside the old `query_predicates.lua` with
--   "attempt to call method 'range' (a nil value)".
-- The `main` branch is the from-scratch rewrite that targets Neovim 0.12+, so
-- that is what we use here.
--
-- The `main` branch is a different plugin: no `require('nvim-treesitter.configs')`,
-- no `ensure_installed` / `highlight` / `indent` option tables. Parsers are
-- installed explicitly and highlighting/indentation are turned on per-buffer via
-- a FileType autocommand (see `:h nvim-treesitter` on the main branch).
--
-- Requires a `tree-sitter` CLI (>= 0.26.1) on PATH plus a C compiler. Installed
-- here via Homebrew (`brew install tree-sitter-cli`; on Homebrew the CLI binary
-- ships as the `tree-sitter-cli` formula, not the `tree-sitter` formula, which
-- is just the C library). On a machine without it, `:TSInstall`/`:TSUpdate`
-- will report the missing executable.

local ensure_installed = {
  'bash',
  'c',
  'css',
  'diff',
  'html',
  'javascript',
  'json',
  'jsdoc',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'php',
  'query',
  'regex',
  'scss',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'vue',
  'yaml',
}

---@module 'lazy'
---@type LazySpec
return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false, -- the main branch explicitly does not support lazy-loading
  build = ':TSUpdate',
  config = function()
    local ts = require 'nvim-treesitter'
    ts.setup {}

    -- Install any parsers from the list above that are missing (async).
    local installed = ts.get_installed 'parsers'
    local missing = vim.tbl_filter(function(lang)
      return not vim.tbl_contains(installed, lang)
    end, ensure_installed)
    if #missing > 0 then
      ts.install(missing)
    end

    -- Turn on highlighting + indentation per buffer, and lazily fetch a parser
    -- the first time an as-yet-uninstalled filetype is opened (this is the
    -- replacement for the old `auto_install = true`).
    local group = vim.api.nvim_create_augroup('nvim_treesitter_start', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = group,
      callback = function(args)
        local buf = args.buf
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        if not lang then
          return
        end

        -- `get_lang()` falls back to the filetype name itself when there's no
        -- explicit mapping (e.g. fidget.nvim's scratch buffers use filetype
        -- "fidget", which isn't a real treesitter language). Bail out quietly
        -- instead of letting `ts.install()` warn "skipping unsupported
        -- language" on every such buffer.
        if not require('nvim-treesitter.parsers')[lang] then
          return
        end

        -- vim regex highlighting is still needed on top of treesitter for a
        -- couple of languages (indent rules etc.); mirror the old config.
        local also_vim_regex = { ruby = true }
        local no_indent = { ruby = true }

        local function start()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          if not pcall(vim.treesitter.start, buf, lang) then
            return
          end
          if not no_indent[lang] then
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
          if also_vim_regex[lang] then
            vim.bo[buf].syntax = 'on'
          end
        end

        if vim.tbl_contains(ts.get_installed 'parsers', lang) then
          start()
        else
          ts.install(lang):await(function(err)
            if not err then
              vim.schedule(start)
            end
          end)
        end
      end,
    })
  end,
}
