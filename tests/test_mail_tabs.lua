-- DOTFILES_MAIL=1 nvim --headless '+luafile tests/test_mail_tabs.lua'
-- Entirely mocked mail backend: no credentials, provider access or sending.
vim.defer_fn(function()
  local ok, err = pcall(function()
    require('lazy').load { plugins = { 'himalaya.nvim' } }
    local s, tabs, reader = require 'himalaya.state', require 'custom.mail_tabs', require 'custom.mail_reader'
    local reads, sent_account = 0, nil
    local messages = {
      { id = 'one', subject = 'First message', flags = {}, from = { { email = 'sender@example.test' } } },
      { id = 'two', subject = "50% %{execute('let g:mail_bad_title=1')}", flags = {}, from = { { email = 'sender@example.test' } } },
    }
    require('himalaya.cli.runner').set_mock(function(cmd, deliver)
      local function callback(err, data)
        vim.schedule(function()
          deliver(err, data)
        end)
      end
      local command = table.concat(cmd, ' ')
      if command:find('mailbox list', 1, true) then
        callback(nil, vim.json.encode { mailboxes = { { name = 'INBOX' }, { name = 'Archive' } } })
      elseif command:find('envelope list', 1, true) then
        callback(nil, vim.json.encode { envelopes = messages })
      elseif command:find('message read', 1, true) then
        reads = reads + 1
        callback(nil, 'Synthetic message ' .. cmd[#cmd])
      elseif command:find('message send', 1, true) then
        for i, arg in ipairs(cmd) do
          if arg == '--account' then
            sent_account = cmd[i + 1]
          end
        end
        callback(nil, 'Mock send accepted')
      elseif command:find('message compose', 1, true) then
        if command:find('--json', 1, true) then
          callback(nil, vim.json.encode { to = {}, cc = {}, bcc = {}, subject = '', body = '' })
        else
          callback(nil, 'From: sender@example.test\nTo: receiver@example.test\n\nSynthetic body')
        end
      else
        error 'Unexpected backend operation: tests must never modify mail'
      end
    end)
    s.current_account = 'fixture'
    require('himalaya').open()
    reader.attach()
    assert(
      vim.wait(1000, function()
        return #s.current_envelopes == 2
      end),
      'No listing'
    )
    local email = require 'himalaya.email'
    local root, win = s.main, s.main_popup.winid
    tabs.focus_index(1)
    assert(tabs.ordered()[1].buf == root, 'Mail is not first')
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
    email.open()
    local first = s.email
    assert(
      vim.wait(1000, function()
        return vim.api.nvim_buf_get_lines(first, 0, 1, false)[1] == 'Synthetic message one'
      end),
      'First message not read'
    )
    email.close()
    assert(tabs.entries[first], 'q discarded the opened message tab')
    vim.api.nvim_win_set_cursor(win, { 2, 0 })
    email.open()
    local second = s.email
    assert(first ~= second, 'Messages reused one buffer')
    assert(
      vim.wait(1000, function()
        return vim.api.nvim_buf_get_lines(second, 0, 1, false)[1] == 'Synthetic message two'
      end),
      'Second message not read'
    )
    assert(#tabs.ordered() == 3, 'Expected Mail plus two messages')
    local count = reads
    tabs.focus_index(1)
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
    email.open()
    assert(s.email == first and reads == count, 'Reopening duplicated/refetched cached message')
    tabs.focus(second)
    assert(email.get_selected_envelope().id == 'two', 'Switching tab lost message identity')
    local rendered = _G.cokeline.tabline()
    vim.api.nvim_eval_statusline(rendered, { use_tabline = true, maxwidth = 1000 })
    assert(not vim.g.mail_bad_title, 'Subject executed statusline syntax')
    assert(tabs.label(second):find('50％', 1, true), 'Subject percent not made literal')
    tabs.focus(root)
    assert(vim.api.nvim_get_current_buf() == root and not s.email_visible, 'Mail tab did not show list')
    tabs.close(root)
    assert(tabs.entries[root], 'Pinned Mail tab closed')
    require('himalaya.folder').switch_to 'Archive'
    tabs.focus(first)
    assert(s.current_account == 'fixture' and s.current_folder == 'INBOX', 'Restoring tab lost backend folder context')
    tabs.close(second)
    assert(not tabs.entries[second] and tabs.entries[first], 'Closing background view affected another tab')
    tabs.close(first)
    assert(vim.api.nvim_get_current_buf() == root and #tabs.ordered() == 1, 'Closing active message did not restore Mail')
    require('custom.mail').compose 'compose'
    assert(
      vim.wait(1000, function()
        return vim.bo.filetype == 'mail'
      end),
      'No composition tab'
    )
    local draft = vim.api.nvim_get_current_buf()
    assert(tabs.entries[draft].kind == 'draft', 'Draft missing from buffer bar')
    vim.api.nvim_buf_set_lines(draft, 0, -1, false, { 'To: ', 'Cc: ', 'Bcc: ', 'Subject: Draft title', '', 'Body' })
    vim.api.nvim_exec_autocmds('TextChanged', { buffer = draft })
    assert(tabs.label(draft):find('Draft title', 1, true), 'Draft subject not reflected in tab')
    tabs.entries[draft].title = 'Draft · Re: The SB MVP Makes His Return'
    assert(tabs.subject(draft, 22) == 'Re: The SB MVP Makes…', 'Draft truncation should keep complete words')
    assert(vim.fn.strdisplaywidth(tabs.subject(draft, 22)) <= 22, 'Subject overflowed its budget')
    local spec = dofile(vim.fn.stdpath 'config' .. '/lua/custom/plugins/tui/cokeline.nvim.lua')
    local ui_buffer = { number = draft, index = 3, is_modified = true }
    local bubble = ''
    for _, component in ipairs(spec.opts.components) do
      bubble = bubble .. (type(component.text) == 'function' and component.text(ui_buffer) or component.text)
    end
    assert(bubble:find('Makes…', 1, true) and bubble:sub(-#' ') == ' ', 'Draft bubble lost subject or rounded end')
    assert(vim.fn.strdisplaywidth(bubble) <= 42, 'Draft capsule exceeds its width budget')

    tabs.focus(root)
    tabs.focus(draft)
    assert(vim.api.nvim_get_current_buf() == draft, 'Draft focus failed')
    vim.ui.select = function(items, opts, callback)
      callback 'Cancel'
    end
    tabs.close(draft)
    assert(tabs.entries[draft], 'Unsaved draft discarded without approval')
    vim.ui.select = function(items, opts, callback)
      callback 'Discard draft view'
    end
    tabs.close(draft)
    assert(not tabs.entries[draft] and vim.api.nvim_get_current_buf() == root, 'Draft close did not return to Mail')
    -- Sending an old draft must complete under its captured account even if
    -- another message tab has since selected a different backend account.
    s.current_account = 'fixture'
    require('custom.mail').compose 'compose'
    assert(
      vim.wait(1000, function()
        return vim.bo.filetype == 'mail'
      end),
      'Second composition missing'
    )
    local outgoing = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(outgoing, 0, -1, false, { 'To: receiver@example.test', 'Cc: ', 'Bcc: ', 'Subject: Synthetic send', '', 'Body' })
    s.current_account = 'other'
    vim.ui.select = function(items, opts, callback)
      callback 'Send'
    end
    vim.cmd 'MailSend'
    assert(
      vim.wait(1000, function()
        return not tabs.entries[outgoing]
      end),
      'Draft callback lost across account switch'
    )
    assert(sent_account == 'fixture', 'Draft sent through wrong account')
  end)
  if not ok then
    print(err)
    vim.cmd 'cquit 1'
  end
  print 'Mail buffer tabs, cached readers, context, titles and safe close passed (mocked backend).'
  vim.cmd 'qa!'
end, 200)
