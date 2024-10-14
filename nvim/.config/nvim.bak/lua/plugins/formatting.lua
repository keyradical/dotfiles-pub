-- return {
--   "nvimtools/none-ls.nvim",
--   dependencies = {
--     'nvim-lua/plenary.nvim',
--     'joechrisellis/lsp-format-modifications.nvim'
--   },
--
--   config = function()
--     local null_ls = require("null-ls")
--     null_ls.setup({
--       sources = {
--         -- null_ls.builtins.formatting.stylua,
--         -- null_ls.builtins.formatting.prettier,
--         -- null_ls.builtins.diagnostics.erb_lint,
--         -- null_ls.builtins.diagnostics.rubocop,
--         -- null_ls.builtins.formatting.rubocop,
--         null_ls.builtins.formatting.clang_format,
--       },
--       on_attach = function(client, bufnr)
--         local augroup_id = vim.api.nvim_create_augroup(
--           "FormatModificationsDocumentFormattingGroup",
--           { clear = false }
--         )
--         vim.api.nvim_clear_autocmds({ group = augroup_id, buffer = bufnr })
--
--         vim.api.nvim_create_autocmd(
--           "BufWritePre",
--           {
--             group = augroup_id,
--             buffer = bufnr,
--             callback = function()
--               local lsp_format_modifications = require"lsp-format-modifications"
--               lsp_format_modifications.format_modifications(client, bufnr)
--             end,
--           }
--         )
--       end
--     })
--   end,
-- }
return {
	{
		"nvimtools/none-ls.nvim",
		opts = function()
			return require("configs.null-ls")
		end,
	},
}
