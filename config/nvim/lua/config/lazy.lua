local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- leader has to be set before any plugin loads
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- set by the loader in ~/.config/nvim/init.lua
local root = vim.g.dotfiles_nvim or vim.fn.stdpath("config")

require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { version = false },
  lockfile = root .. "/lazy-lock.json",
  install = { colorscheme = { "tokyonight-night", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
  performance = {
    rtp = {
      reset = false, -- or lazy drops what the loader put on the rtp
      disabled_plugins = { "matchparen", "tohtml", "tutor" },
    },
  },
})
