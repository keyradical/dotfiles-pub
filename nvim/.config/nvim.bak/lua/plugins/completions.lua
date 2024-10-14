-- Language servers
local ensure_installed = {
  'clangd',    -- C/C++
  'lua_ls',    -- Lua
  'opencl_ls', -- OpenCL
}

if vim.fn.executable('npm') == 1 then
  local ensure_install_from_npm = {
    'ansiblels',                       -- Ansible
    'bashls',                          -- Bash
    'docker_compose_language_service', -- Docker Compose
    'dockerls',                        -- Dockerfile
    'html',                            -- HTML
    'jsonls',                          -- JSON
    'pyright',                         -- Python
    'vimls',                           -- VimScript
    'yamlls',                          -- YAML
  }
  for _, package in ipairs(ensure_install_from_npm) do
    table.insert(ensure_installed, package)
  end
end

if vim.fn.executable('pip') == 1 then
  local ensure_install_from_pip = {
    'cmake',    -- CMake
    'esbonio',  -- Sphinx
    'ruff_lsp', -- Python
  }
  for _, package in ipairs(ensure_install_from_pip) do
    table.insert(ensure_installed, package)
  end
end

if vim.fn.has('win32') == 1 then
  table.insert(ensure_installed, 'powershell_es')
end

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Language server management plugins
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',

    -- Completion sources plugins
    'hrsh7th/cmp-nvim-lsp',     -- Source for built-in language server client
    'saadparwaiz1/cmp_luasnip', -- Source for LuaSnip snippets
    'hrsh7th/cmp-buffer',       -- Source for buffer words
    'hrsh7th/cmp-path',         -- Source for filesystem paths
    'petertriho/cmp-git',          -- Source for Git/GitHub/GitLab
    'hrsh7th/nvim-cmp',         -- Completion engine combines and uses the above

    -- Lua vim module support in lua language server
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
    -- Expose clangd extensions
    'p00f/clangd_extensions.nvim',

    -- LSP UI plugins
    'aznhe21/actions-preview.nvim',
    'j-hui/fidget.nvim',
    'nvim-tree/nvim-web-devicons',
    'ray-x/lsp_signature.nvim',
  },

  config = function()
    require("nvchad.configs.lspconfig").defaults()
    local lspconfig_default_opts = require "lspconfig"

    local lspconfig_custom_opts = {
      clangd = {
        cmd = { 'clangd', '--completion-style=detailed' },
      },

      lua_ls = {
        settings = {
          Lua = {
            diagnostics = {
              disable = { 'missing-fields', },
              globals = { 'vim', },
            },
          },
        },
      },

      pyright = {
        settings = {
          pyright = {
            disableOrganizeImports = true,
          },
        },
      },
    }

    require('mason').setup()
    require('mason-lspconfig').setup({
      automatic_installation = false,
      ensure_installed = ensure_installed,
      handlers = {
        function(server_name)
          local opts = vim.tbl_deep_extend("force",
            lspconfig_default_opts, lspconfig_custom_opts[server_name] or {})
          require('lspconfig')[server_name].setup(opts)
        end,
      },
    })

    local cmp = require('cmp')
    cmp.setup({
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end
      },

      mapping = cmp.mapping.preset.insert({
        -- Open completion menu/confirm completion
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-l>'] = cmp.mapping.confirm({ select = true }),
        -- Select completion from menu
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        -- Scroll documentation of selected completion item
        ['<C-d>'] = cmp.mapping.scroll_docs(4),
        ['<C-u>'] = cmp.mapping.scroll_docs(-4),
      }),

      sources = {
        { name = 'luasnip' },
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' },
        { name = 'git' },
      },

      formatting = {
        format = function(entry, vim_item)
          -- Set a limit to how wide the completion menu can be
          local winwidth = vim.fn.winwidth(vim.api.nvim_get_current_win())
          local menuwidth = math.min(winwidth / 2, 70)
          if menuwidth < 70 then
            vim_item.menu = ''
            vim_item.kind = ''
          end
          vim_item.abbr = string.sub(vim_item.abbr, 1, menuwidth)
          return vim_item
        end
      },

      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },

      preselect = 'none', -- Don't preselect completions suggested by source
    })
    require("cmp_git").setup({})

    -- Mappings created when LSP is attached to a buffer
    local augroup = vim.api.nvim_create_augroup('lsp', { clear = true })
    vim.api.nvim_create_autocmd('LspAttach', {
      pattern = '*',
      group = augroup,
      callback = function(event)
        local opts = { noremap = true, buffer = event.buf }

        -- Fixit mapping, or close enough, actually any code action
        vim.keymap.set('n', '<leader>fi',
          require('actions-preview').code_actions, opts)

        -- Goto mappings
        local tb = require('telescope.builtin')
        vim.keymap.set('n', 'gd', tb.lsp_definitions, opts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gi', tb.lsp_implementations, opts)
        vim.keymap.set('n', 'go', tb.lsp_type_definitions, opts)
        vim.keymap.set('n', 'gr', tb.lsp_references, opts)
        vim.keymap.set('n', '<leader>ic', tb.lsp_incoming_calls, opts)
        vim.keymap.set('n', '<leader>oc', tb.lsp_outgoing_calls, opts)
        vim.keymap.set('n', '<leader>sd', tb.lsp_document_symbols, opts)
        vim.keymap.set('n', '<leader>sw', tb.lsp_workspace_symbols, opts)

        -- Refactoring mappings
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)

        -- Help mappings
        -- TODO: v0.10.0 |vim.lsp.start()| now maps |K| to use
        -- |vim.lsp.buf.hover()| if the server supports it, unless
        -- |'keywordprg'| was customized before calling |vim.lsp.start()|.
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

        -- Format whole buffer mapping
        vim.keymap.set('n', '<leader>gq', vim.lsp.buf.format, opts)

        -- Swtich file using clangd extension
        -- TODO: limit this to only filetypes supported by clangd
        vim.keymap.set('n', '<leader>sf',
          ':ClangdSwitchSourceHeader<CR>', { silent = true })
      end
    })

    -- LSP UI plugins
    require('fidget').setup({})
    require('lsp_signature').setup({
      floating_window = true,
      hint_enable = false,
      toggle_key = '<C-h>',
      toggle_key_flip_floatwin_setting = true,
      select_signature_key = '<C-l>',
    })
  end
}

