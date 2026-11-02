return {
  {
    'voldikss/vim-floaterm',
    config = function()
      -- Unless you are still migrating, remove the deprecated commands from v1.x
      vim.keymap.set('n', '<leader>gs', ':FloatermNew nvim -c ":G" +only<cr>', { desc = 'Open terminal and show git status' })
      vim.keymap.set('n', '<leader>gg', ':vertical G<cr>', { desc = 'Show git status' })
      vim.keymap.set('n', '<leader>ft', ':FloatermToggle<cr>', { desc = 'Toggle terminal.' })

      -- Run the current buffer in a floating terminal. Uses a filetype-specific
      -- interpreter if one is listed, otherwise falls back to $SHELL.
      local runners = {
        lua = 'nvim -l',
        python = 'python3',
        javascript = 'node',
        typescript = 'npx tsx',
        php = 'php',
        ruby = 'ruby',
        go = 'go run',
        perl = 'perl',
      }

      vim.keymap.set('n', '<leader>fr', function()
        -- Default to the current shell for anything without a dedicated runner
        local runner = runners[vim.bo.filetype] or vim.env.SHELL or vim.o.shell
        local path = vim.api.nvim_buf_get_name(0)
        if path == '' then
          -- Unnamed buffer: run its contents from a temp file
          path = vim.fn.tempname()
          vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), path)
        elseif vim.bo.modified then
          vim.cmd 'write'
        end
        local file = vim.fn.shellescape(path)
        -- --autoclose=never keeps the window open after the command exits so you can read the output
        vim.cmd(('FloatermNew --autoclose=never --cwd=<buffer> %s %s'):format(runner, file))
      end, { desc = 'Run current buffer in float term' })
    end,
  },
}
