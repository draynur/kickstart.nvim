return {
  {
    'MeanderingProgrammer/markdown.nvim',
    name = 'render-markdown', -- Only needed if you have another plugin named markdown.nvim
    dependencies = {
      'nvim-treesitter/nvim-treesitter', -- Mandatory
      'nvim-tree/nvim-web-devicons', -- Optional but recommended
    },
    config = function()
      require('render-markdown').setup {
        enabled = true,
      }
    end,
  },
  -- install with yarn or npm
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = 'cd app && yarn install',
    init = function()
      vim.g.mkdp_filetypes = { 'markdown' }
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 1
      vim.g.mkdp_echo_preview_url = 1
    end,
    ft = { 'markdown' },
  },
}
