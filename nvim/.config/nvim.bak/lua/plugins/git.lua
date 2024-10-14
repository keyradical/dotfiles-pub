return {
  { 'tpope/vim-fugitive', lazy = false },
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({})
    end
  },
}

