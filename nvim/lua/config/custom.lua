vim.api.nvim_create_user_command("TSCCheck", function()
  vim.cmd("!npx tsc --noEmit")
end, {})
