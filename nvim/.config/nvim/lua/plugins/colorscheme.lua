return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,

    opts = {
      flavour = "mocha",

      transparent_background = true,

      integrations = {
        cmp = true,
        gitsigns = true,
        telescope = true,
        treesitter = true,
        notify = true,
        snacks = true,
        mason = true,
        which_key = true,
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
