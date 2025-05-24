return {
  "neo-tree.nvim",
  opts = {
    filesystem = {
      follow_current_file = {
        enabled = true,
        leave_dirs_open = true,
        open_files_in_new_tab = true,
      },
      hijack_netrw_behavior = "open_current",
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false, -- hide filtered items on open
        hide_gitignored = true,
        hide_dotfiles = false,
        hide_by_name = {
          -- ".github",
          "thumbs.db",
          ".DS_Store",
          ".gitignore",
          "package-lock.json",
          ".changeset",
          ".prettierrc.json",
        },
        never_show = { ".git" },
      },
    },
  },
}