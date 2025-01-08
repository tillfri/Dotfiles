return {
    dir = "~/.config/nvim/lua/local", -- Treat this as a local plugin
    name = "floaterminal", -- Give the plugin a name
    lazy = true,
    config = function()
        require("local.floaterminal").setup()
    end,
    keys = {
        { "<leader>tt", ":Floaterminal<CR>", desc = "Toggle floating terminal" }, -- Keybinding for space + tt
        -- { "<leader>xp", ":Flonceterminal<CR>", desc = "Toggle floating terminal and execute python" }, -- Keybinding for space + xp
    },
}
