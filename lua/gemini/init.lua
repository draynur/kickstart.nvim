local M = {}

-- Creates a small floating window to show a spinner/loading message.
local function create_spinner_window()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.5)
  local height = 1
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'rounded',
  }
  local win = vim.api.nvim_open_win(buf, true, opts)
  return win, buf
end

-- Makes a real request to the Google Gemini API via a curl job.
-- While waiting, a spinner animation is shown.
local function gemini_request(input, callback)
  -- Create a spinner window and start the animation.
  local spinner_win, spinner_buf = create_spinner_window()
  local spinner_chars = { '-', '\\', '|', '/' }
  local spinner_index = 1
  local spinner_timer = vim.loop.new_timer()
  spinner_timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      if vim.api.nvim_buf_is_valid(spinner_buf) then
        vim.api.nvim_buf_set_lines(spinner_buf, 0, -1, false, { 'Loading... ' .. spinner_chars[spinner_index] })
        spinner_index = spinner_index % #spinner_chars + 1
      end
    end)
  )

  -- Build the JSON payload using the input text.
  local payload_table = {
    contents = {
      {
        parts = {
          { text = input },
        },
      },
    },
  }

  local payload = vim.fn.json_encode(payload_table)
  local api_key = os.getenv 'GEMINI_API_KEY'

  if not api_key or api_key == '' then
    vim.notify('GEMINI_API_KEY is missing from your system environment!', vim.log.levels.ERROR)
    return
  end

  local url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=' .. api_key

  local cmd = {
    'curl',
    url,
    '-H',
    'Content-Type: application/json',
    '-X',
    'POST',
    '-d',
    payload,
  }

  local stdout_data = {}
  local stderr_data = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(stdout_data, line)
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(stderr_data, line)
          end
        end
      end
    end,
    on_exit = vim.schedule_wrap(function(_, exit_code, _)
      spinner_timer:stop()
      spinner_timer:close()

      local raw_response = table.concat(stdout_data, '\n')
      local response_text, meta

      local ok, decoded = pcall(vim.fn.json_decode, raw_response)
      if ok and decoded and decoded.candidates and decoded.candidates[1] then
        local candidate = decoded.candidates[1]
        response_text = candidate.content.parts[1].text or 'No response text found.'
        local finishReason = candidate.finishReason or 'N/A'
        local modelVersion = decoded.modelVersion or 'N/A'
        local usage = decoded.usageMetadata or {}
        local usage_info = string.format(
          'Prompt tokens: %s, Candidate tokens: %s, Total tokens: %s',
          usage.promptTokenCount or 'N/A',
          usage.candidatesTokenCount or 'N/A',
          usage.totalTokenCount or 'N/A'
        )
        meta = string.format('Finish Reason: %s | Model Version: %s\nUsage: %s', finishReason, modelVersion, usage_info)
      else
        response_text = 'Failed to decode response: ' .. raw_response
        meta = 'Error retrieving meta information. ' .. table.concat(stderr_data, '\n')
      end

      -- Increase the window size to show the full response.
      if vim.api.nvim_win_is_valid(spinner_win) then
        local new_width = math.floor(vim.o.columns * 0.8)
        local new_height = math.floor(vim.o.lines * 0.8)
        local new_row = math.floor((vim.o.lines - new_height) / 2 - 1)
        local new_col = math.floor((vim.o.columns - new_width) / 2)
        local new_opts = {
          style = 'minimal',
          relative = 'editor',
          width = new_width,
          height = new_height,
          row = new_row,
          col = new_col,
          border = 'rounded',
        }
        vim.api.nvim_win_set_config(spinner_win, new_opts)
      end

      -- Update the window with the final response.
      if vim.api.nvim_win_is_valid(spinner_win) then
        local lines = {}
        for line in response_text:gmatch '[^\n]+' do
          table.insert(lines, line)
        end
        vim.api.nvim_buf_set_lines(spinner_buf, 0, -1, false, lines)
        vim.api.nvim_buf_set_option(spinner_buf, 'filetype', 'markdown')
        vim.api.nvim_buf_set_var(spinner_buf, 'gemini_meta', meta)
        -- Set key mappings on the final window.
        vim.api.nvim_buf_set_keymap(
          spinner_buf,
          'n',
          'q',
          "<cmd>lua require'gemini'.close_current_window(" .. spinner_win .. ')<CR>',
          { noremap = true, silent = true }
        )
        vim.api.nvim_buf_set_keymap(
          spinner_buf,
          'n',
          't',
          "<cmd>lua require'gemini'.open_in_new_tab(" .. spinner_win .. ')<CR>',
          { noremap = true, silent = true }
        )
        vim.api.nvim_buf_set_keymap(spinner_buf, 'n', '?', "<cmd>lua require'gemini'.show_meta(" .. spinner_win .. ')<CR>', { noremap = true, silent = true })
      end

      callback(response_text, meta, spinner_win)
    end),
  })
end

-- Public function to trigger the Gemini API request.
-- It gets the input text from the current buffer and calls gemini_request.
function M.run()
  local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local input = table.concat(buf_lines, '\n')
  gemini_request(input, function(response, meta, _win)
    -- The window is updated in-place with the API response.
  end)
end

-- Close the floating window.
function M.close_current_window(win)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end

-- Open the floating window content in a new tab.
function M.open_in_new_tab(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local content = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_win_close(win, true)
  vim.cmd 'tabnew'
  local new_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(new_buf, 'filetype', 'markdown')
  vim.api.nvim_set_current_buf(new_buf)
end

-- Display meta information at the top of the floating window.
function M.show_meta(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local buf = vim.api.nvim_win_get_buf(win)
  local meta = vim.api.nvim_buf_get_var(buf, 'gemini_meta')
  local meta_lines = {}
  for line in meta:gmatch '[^\n]+' do
    table.insert(meta_lines, line)
  end
  table.insert(meta_lines, '') -- Optional: add an extra blank line
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, meta_lines)
end

return M
