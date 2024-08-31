return {
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = {
  		ensure_installed = {
  			"vim", "lua", "vimdoc",
       "html", "css", "javascript", "rust", "zig",
  		},
  	},
  },

  {
"yetone/avante.nvim",
event = "VeryLazy",
lazy = false,
opts = {
  providers="claude",
},
keys = {
  { "<leader>aa", function() require("avante.api").ask() end, desc = "avante: ask", mode = { "n", "v" } },
  { "<leader>ar", function() require("avante.api").refresh() end, desc = "avante: refresh" },
  { "<leader>ae", function() require("avante.api").edit() end, desc = "avante: edit", mode = "v" },
},
dependencies = {
  "stevearc/dressing.nvim",
  "nvim-lua/plenary.nvim",
  "MunifTanjim/nui.nvim",
  "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        use_absolute_path = true,
      },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
  },
},
}
}
