return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    name = 'render-markdown', -- Only needed if you have another plugin named markdown.nvim
    dependencies = {
      'nvim-treesitter/nvim-treesitter', -- Mandatory -- configured in custom/plugins/treesitter.lua (main branch)
      'nvim-tree/nvim-web-devicons', -- Optional but recommended
    },
    ft = { 'markdown', 'markdown.mdx', 'codecompanion' },
    config = function()
      require('render-markdown').setup {
        enabled = true,
        -- No `latex` parser installed; turning it off avoids checkhealth
        -- warnings and stray errors on math blocks inside markdown.
        latex = { enabled = false },
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
