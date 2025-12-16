return {
  {
    'voldikss/vim-floaterm',
    config = function()
      -- Unless you are still migrating, remove the deprecated commands from v1.x
      vim.keymap.set('n', '<leader>gs', ':FloatermNew nvim -c ":G" +only<cr>', { desc = 'Open terminal and show git status' })
      vim.keymap.set('n', '<leader>gg', ':vertical G<cr>', { desc = 'Show git status' })
      vim.keymap.set('n', '<leader>ft', ':FloatermToggle<cr>', { desc = 'Toggle terminal.' })
    end,
  },
}
