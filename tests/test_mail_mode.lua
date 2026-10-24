-- From the deployed dotfiles checkout, with the mail plugins installed:
-- DOTFILES_MAIL=1 nvim --headless '+luafile tests/test_mail_mode.lua'
-- This checks configuration only; it never opens an account or contacts a server.
vim.defer_fn(function()
  local ok, err = pcall(function()
    assert(vim.g.dotfiles_mail_mode, 'Run with DOTFILES_MAIL=1')
    local config = require 'lazy.core.config'
    local allowed = {
      ['lazy.nvim'] = true,
      tokyonight = true,
      ['snacks.nvim'] = true,
      ['which-key.nvim'] = true,
      ['himalaya.nvim'] = true,
      ['nui.nvim'] = true,
      ['mini.nvim'] = true,
      ['nvim-autopairs'] = true,
      ['nvim-cokeline'] = true,
      ['nvim-web-devicons'] = true,
    }
    for name in pairs(config.plugins) do
      assert(allowed[name], 'Unexpected mail plugin: ' .. name)
    end
    assert(vim.tbl_count(config.plugins) == 10, 'Expected the ten mail plugin definitions')
    for _, plugin in ipairs(config.to_clean) do
      assert(plugin.name ~= 'nvim-lspconfig' and plugin.name ~= 'agentic.nvim' and plugin.name ~= 'nvim-cmp', 'Editor checkout proposed for cleanup')
    end
    for _, key in ipairs {
      '<leader>da',
      '<leader>db',
      '<leader>sv',
      '<leader>q',
      '<leader>sf',
      '<leader>sg',
      '<leader>pp',
      '<leader>.',
      '<leader>e',
    } do
      assert(vim.fn.maparg(key, 'n') == '', 'Editor keymap remains: ' .. key)
    end
    assert(vim.fn.maparg('<leader>sk', 'n') ~= '', 'Keymap picker missing')
    assert(not Snacks.config.scroll.enabled and not Snacks.config.scratch.enabled, 'Unwanted Snacks features enabled')
    vim.cmd 'enew'
    vim.bo.filetype = 'mail'
    assert(vim.wo.spell, 'Composer spell-check missing')
    assert(config.plugins['mini.nvim']._.loaded, 'Composition helpers not loaded')
    assert(not package.loaded['mini.git'], 'Git integration loaded in mail')
    vim.api.nvim_exec_autocmds('InsertEnter', {})
    assert(config.plugins['nvim-autopairs']._.loaded, 'Autopairs missing')
    assert(not package.loaded.cmp, 'Coding completion stack loaded')
  end)
  if not ok then
    print(err)
    vim.cmd 'cquit 1'
  end
  print 'Mail plugin/keymap isolation passed (no accounts accessed).'
  vim.cmd 'qa!'
end, 200)
