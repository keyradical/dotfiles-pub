return {
  {
    "folke/trouble.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("trouble").setup({})
      local opts = { remap = false }
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      vim.keymap.set("n", "<leader>ds", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "<leader>dq", function()
        require("trouble").toggle()
      end, opts)
    end,
  },
}
