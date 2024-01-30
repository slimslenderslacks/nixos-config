{ sources }:
''
"--------------------------------------------------------------------
" Fix vim paths so we load the vim-misc directory
let g:vim_home_path = "~/.vim"

" This works on NixOS 21.05
let vim_misc_path = split(&packpath, ",")[0] . "/pack/home-manager/start/vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

" This works on NixOS 21.11
let vim_misc_path = split(&packpath, ",")[0] . "/pack/home-manager/start/vimplugin-vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

" This works on NixOS 22.11
let vim_misc_path = split(&packpath, ",")[0] . "/pack/myNeovimPackages/start/vimplugin-vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

lua <<EOF

require('nvim-treesitter').setup()
---------------------------------------------------------------------
-- Add our custom treesitter parsers

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()

parser_config.proto = {
  install_info = {
    url = "${sources.tree-sitter-proto}", -- local path or git repo
    files = {"src/parser.c"}
  },
  filetype = "proto", -- if filetype does not agrees with parser name
}

---------------------------------------------------------------------
-- Add our treesitter textobjects
require'nvim-treesitter.configs'.setup {
  textobjects = {
    select = {
      enable = true,
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },

    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
    },
  },
}

local ollama = require('ollama')
ollama.setup()

local nixPackPath = vim.opt.runtimepath:get()[1]

-- lazy bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lazy setup
require("lazy").setup({

  -- these are in the wrong place (lazy bug)
  -- 'tpope/vim-fugitive',
  -- 'preservim/nerdtree',
     'preservim/nerdcommenter',
  -- {'kovisoft/paredit', commit = '3609c637d1be6bfea21dc4930f0901f2430d665b'},
  -- 'junegunn/goyo.vim',
  --

  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = true,
  },
  { 'projekt0n/github-nvim-theme',
     lazy = false,
     priority = 1000,
     tag = 'v0.0.7',
     config = function()
       require('github-theme').setup( { theme_style = 'dark', comment_style = 'italic', } )
     end,
  },
  { 'Olical/aniseed',
    lazy = false,
    branch = 'develop' 
  },
  {
    'Olical/conjure',
    branch = 'master',
    lazy = false,
    config = function()
      vim.g["conjure#mapping#doc_word"] = "K"
      vim.g["conjure#client#clojure#nrepl#eval#auto_require"] = false
      vim.g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = false
      vim.g["conjure#client#clojure#nrepl#eval#raw_out"] = true
      vim.g["conjure#log#wrap"] = true
    end,
  },
  {
    'L3MON4D3/LuaSnip',
    dependencies = { 'saadparwaiz1/cmp_luasnip' }
  },
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {'nvim-telescope/telescope-ui-select.nvim',
                    'nvim-lua/popup.nvim',
                    'nvim-lua/plenary.nvim'},
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {'hrsh7th/cmp-buffer',
                    'hrsh7th/cmp-nvim-lsp',
                    'hrsh7th/cmp-vsnip',
                    'PaterJason/cmp-conjure'}
  },
  {
    'slimslenderslacks/nvim-cmp-lsp-inline-completion',
    dir = '/Users/slim/slimslenderslacks/nvim-cmp-lsp-inline-completion/'
  },
  {
    'slimslenderslacks/nvim-lspconfig',
  },
  {
    'slimslenderslacks/nvim-docker-ai',
    dir = '/Users/slim/slimslenderslacks/nvim-docker-ai',
    lazy = false,
    dependencies = {
      'Olical/aniseed',
      'nvim-lua/plenary.nvim',
      'hrsh7th/nvim-cmp',
    },
    config = function(plugin, opts)
      require("dockerai")
    end,
  },
}, 
	{ performance = { reset_packpath = false, 
	                  rtp = { reset = false, },}})

-- Lazy now takes over step 10 of neovim plugin loading - re-enable it because it will be false
vim.go.loadplugins = true

-- Enable Aniseed's automatic compilation and loading of Fennel source code.
require('aniseed.env').init( { module = 'config.init', compile = true, })

EOF
''
