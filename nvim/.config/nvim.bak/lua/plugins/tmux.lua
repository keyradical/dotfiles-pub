return {
  'alexghergh/nvim-tmux-navigation',
  config = function()
    local plugin = require('nvim-tmux-navigation')
    plugin.setup({
      disable_when_zoomed = true,
    })

    -- Integrate tmux navigation flag
    local navigation_flag =
      '@vim' .. vim.fn.substitute(vim.env.TMUX_PANE, '%', '\\%', 'g')
    local function set_navigation_flag()
      vim.fn.system('tmux set-window-option ' .. navigation_flag .. ' 1')
    end
    local function unset_navigation_flag()
      -- FIXME: Due to a regression this causes SIGABRT when RelWithDebInfo
      -- vim.fn.system('tmux set-window-option -u ' .. navigation_flag)
      -- https://github.com/neovim/neovim/issues/21856 contains a workaround
      vim.fn.jobstart(
        'tmux set-window-option -u ' .. navigation_flag, { detach = true})
    end

    -- [Un]set tmux window option to detect when to change pane.
    set_navigation_flag()
    local augroup = vim.api.nvim_create_augroup('tmux', { clear = true })
    vim.api.nvim_create_autocmd('FocusGained', {
      pattern = '*', group = augroup, callback = set_navigation_flag,
    })
    vim.api.nvim_create_autocmd('VimLeave', {
      pattern = '*', group = augroup, callback = unset_navigation_flag,
    })

    -- Map nativation bindings
    vim.keymap.set("n", "<C-h>", "<Cmd>NvimTmuxNavigateLeft<CR>", {})
    vim.keymap.set("n", "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", {})
    vim.keymap.set("n", "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", {})
    vim.keymap.set("n", "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", {})
  end
}

