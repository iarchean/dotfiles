return {
  "catppuccin/nvim",
  name = "catppuccin",
  opts = {
    transparent_background = true,
    -- dim_inactive = { enabled = true, percentage = 0.25 },
    -- highlight_overrides = {
    --   mocha = function(c)
    --     return {
    --       Comment = { fg = "#7687a0" },
    --       ["@tag.attribute"] = { style = {} },
    --     }
    --   end,
    -- },
    integrations = {
      sandwich = false,
      noice = true,
      mini = true,
      leap = true,
      markdown = true,
      neotest = true,
      cmp = true,
      overseer = true,
      lsp_trouble = true,
      rainbow_delimiters = true,
      neotree = true,
    },
  },
}
