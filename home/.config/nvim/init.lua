-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local function transparent_bg()
  local groups = {
    "Normal",
    "NormalNC",
    "SignColumn",
    "EndOfBuffer",
    "NormalFloat",
    "FloatBorder",
  }

  for _, group in ipairs(groups) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
  end
end

transparent_bg()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = transparent_bg,
})
