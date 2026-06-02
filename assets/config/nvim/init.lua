-- PLUGINS
vim.pack.add({
    'https://github.com/nvim-tree/nvim-web-devicons',
    'https://github.com/nvim-lualine/lualine.nvim',
    'https://github.com/folke/tokyonight.nvim',
    'https://github.com/norcalli/nvim-colorizer.lua'
})

-- VIM OPTIONS
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.number = true
vim.opt.relativenumber = true
    
-- SET COLORSCHEME
vim.cmd.colorscheme "tokyonight"

-- LUALINE PLUG IN OPSTIONS
require('lualine').setup {
    options = { theme = 'tokyonight' }
}

-- COLORIZER PLUG IN
require 'colorizer'.setup()
