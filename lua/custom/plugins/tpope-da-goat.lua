return {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  {
    'tpope/vim-fugitive', --  Badass Git shit
    config = function()
      -- Fugitive fires `User FugitivePager` when it shows command output (:G log, :G diff, :G show, ...)
      -- in a split. Move that buffer into a centered floating window instead.
      vim.api.nvim_create_autocmd('User', {
        pattern = 'FugitivePager',
        group = vim.api.nvim_create_augroup('fugitive-float-pager', { clear = true }),
        callback = function()
          local split_win = vim.api.nvim_get_current_win()
          local buf = vim.api.nvim_get_current_buf()

          -- Already in a float (e.g. running :G log from inside one), leave it alone
          if vim.api.nvim_win_get_config(split_win).relative ~= '' then
            return
          end

          -- Defer so fugitive finishes setting up the buffer before we move it
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then
              return
            end

            -- Pager buffers are temp files, so title the float with the git command that produced it
            local ok, result = pcall(vim.fn.FugitiveResult, buf)
            local title = (ok and type(result) == 'table' and result.args) and ('git ' .. table.concat(result.args, ' ')) or 'fugitive'

            local width = math.floor(vim.o.columns * 0.9)
            local height = math.floor((vim.o.lines - vim.o.cmdheight) * 0.85)

            -- Open the float first so the buffer stays displayed (fugitive pager buffers get wiped when hidden)
            vim.api.nvim_open_win(buf, true, {
              relative = 'editor',
              width = width,
              height = height,
              row = math.floor((vim.o.lines - height) / 2) - 1,
              col = math.floor((vim.o.columns - width) / 2),
              style = 'minimal',
              border = 'rounded',
              title = ' ' .. title .. ' ',
              title_pos = 'center',
            })

            -- Then drop the split fugitive created (unless it's the last window)
            if vim.api.nvim_win_is_valid(split_win) and #vim.api.nvim_tabpage_list_wins(0) > 2 then
              vim.api.nvim_win_close(split_win, true)
            end
          end)
        end,
      })
    end,
  },
}
