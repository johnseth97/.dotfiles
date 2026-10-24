-- Run from the deployed checkout with mail plugins installed:
-- DOTFILES_MAIL=1 nvim --headless '+luafile tests/test_mail_reader.lua'
-- Every backend request is mocked; no account/config/credential access occurs.
vim.defer_fn(function()
  local ok, err = pcall(function()
    require('lazy').load { plugins = { 'himalaya.nvim' } }
    local s = require 'himalaya.state'
    local messages = {
      { id = 'first', subject = 'Synthetic first', flags = {}, from = { { email = 'sender@example.test' } } },
      { id = 'second', subject = 'Synthetic second', flags = {}, from = { { email = 'sender@example.test' } } },
    }
    require('himalaya.cli.runner').set_mock(function(cmd, callback)
      local deliver = callback
      callback = function(failure, result)
        vim.schedule(function()
          deliver(failure, result)
        end)
      end
      local command = table.concat(cmd, ' ')
      if command:find('mailbox list', 1, true) then
        callback(nil, vim.json.encode { mailboxes = { { name = 'INBOX' }, { name = 'Archive' } } })
      elseif command:find('envelope list', 1, true) then
        callback(nil, vim.json.encode { envelopes = messages })
      elseif command:find('message read', 1, true) then
        callback(nil, 'Synthetic body')
      elseif command:find('message reply', 1, true) then
        callback(
          nil,
          vim.json.encode {
            to = { 'sender@example.test' },
            subject = 'Re: Synthetic',
            body = '> Synthetic body',
          }
        )
      else
        error 'Unexpected backend request'
      end
    end)
    s.current_account = 'fixture'
    require('himalaya').open()
    require('custom.mail_reader').attach()
    assert(
      vim.wait(1000, function()
        return #s.current_envelopes == 2
      end),
      'Listing missing'
    )
    local bulk
    require('himalaya.cli.flag').add = function(opts, callback)
      bulk = opts
    end
    require('custom.mail').mark_selection_read(2, 1)
    assert(bulk and bulk.flag == 'seen' and #bulk.ids == 2, 'Bulk read flag request missing')
    assert(bulk.ids[1] == 'first' and bulk.ids[2] == 'second' and bulk.mailbox == 'INBOX', 'Bulk selection IDs/folder incorrect')
    assert(vim.fn.maparg('gFa', 'x') ~= '', 'Bulk visual mapping missing')
    local email = require 'himalaya.email'
    local win = s.main_popup.winid
    local height = vim.api.nvim_win_get_height(win)
    vim.api.nvim_win_set_cursor(win, { 2, 0 })
    email.open()
    assert(vim.api.nvim_win_get_buf(win) == s.email, 'Reader did not replace the list')
    assert(vim.fn.bufwinid(s.main) == -1, 'List remains visible')
    assert(not s.email_popup.winid, 'A reading split was created')
    assert(vim.api.nvim_win_get_height(win) == height, 'Reader lost pane height')
    assert(email.get_selected_envelope().id == 'second', 'Selected row lost')
    assert(
      vim.wait(1000, function()
        return vim.api.nvim_buf_get_lines(s.email, 0, 1, false)[1] == 'Synthetic body'
      end),
      'Message missing'
    )
    require('custom.mail').compose 'reply'
    assert(
      vim.wait(1000, function()
        return vim.bo.filetype == 'mail'
      end),
      'Reply form missing'
    )
    assert(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n'):find('> Synthetic body', 1, true), 'Quote missing')
    vim.api.nvim_buf_delete(0, { force = true })
    email.close()
    assert(vim.api.nvim_win_get_buf(win) == s.main and vim.api.nvim_win_get_cursor(win)[1] == 2, 'List/cursor not restored')
    email.open()
    require('himalaya.folder').switch_to 'Archive'
    assert(not s.email_visible and vim.api.nvim_win_get_buf(win) == s.main, 'Folder switch retained old message')
  end)
  if not ok then
    print(err)
    vim.cmd 'cquit 1'
  end
  print 'Mail replacement reader and quoted reply passed (mocked backend).'
  vim.cmd 'qa!'
end, 200)
