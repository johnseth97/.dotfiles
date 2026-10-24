"""Run: python3 -m unittest discover -s tests -p 'test_mail_accounts.py'.

All config edits use temporary synthetic accounts. Native wizard/login calls
are mocked; no mail server or real credential store is contacted.
"""
from contextlib import ExitStack, redirect_stderr
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'common/.bin/nvim-mail-account'
NS = runpy.run_path(str(SCRIPT))
GLOBALS = NS['main'].__globals__


class AccountManagementTests(unittest.TestCase):
    def test_remove_preserves_other_settings_and_comments(self):
        text = '''# Global comment
downloads-dir = "~/Downloads"
[accounts.personal]
default = true
email = "personal@example.test"
imap.server = "imap.example.test"

# Keep this heading for the next account.
[accounts."work.mail"]
email = "work@example.test"
[accounts."work.mail".msgraph]
user-id = "me"
[accounts.other]
email = "other@example.test"
'''
        result = NS['remove_account'](text, 'work.mail')
        self.assertIn('# Global comment', result)
        self.assertIn('# Keep this heading', result)
        self.assertNotIn('work@example.test', result)
        expected = NS['tomllib'].loads(text)
        del expected['accounts']['work.mail']
        self.assertEqual(NS['tomllib'].loads(result), expected)

    def test_last_account_removal_keeps_globals(self):
        text = 'downloads-dir = "~/Downloads"\n[accounts.one]\nemail = "one@example.test"\n'
        self.assertEqual(NS['tomllib'].loads(NS['remove_account'](text, 'one')), {'downloads-dir': '~/Downloads'})

    def test_inline_layout_refused(self):
        with self.assertRaises(ValueError):
            NS['remove_account']('accounts = {one = {email = "one@example.test"}}\n', 'one')

    def test_multiline_header_decoy_cannot_damage_other_account(self):
        text = '''[accounts.keep]
signature = """
[accounts.remove]
example text
"""
[accounts.remove]
email = "remove@example.test"
'''
        with self.assertRaises(ValueError):
            NS['remove_account'](text, 'remove')

    def test_missing_account_refused(self):
        with self.assertRaises(ValueError):
            NS['remove_account']('[accounts.one]\nemail="one@example.test"\n', 'missing')

    def environment(self, root, config, answer=None):
        stack = ExitStack()
        stack.enter_context(patch.dict(os.environ, HIMALAYA_CONFIG=str(config), XDG_CONFIG_HOME=str(root)))
        stack.enter_context(patch('sys.stdin.isatty', return_value=True))
        stack.enter_context(patch('sys.stdout.isatty', return_value=True))
        stack.enter_context(redirect_stderr(io.StringIO()))
        if answer is not None:
            stack.enter_context(patch('builtins.input', return_value=answer))
        return stack

    def test_confirmed_delete_backup_and_permissions(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / 'config.toml'
            original = '[accounts.one]\ndefault=true\nemail="one@example.test"\n[accounts.two]\nemail="two@example.test"\n'
            config.write_text(original)
            with self.environment(root, config, 'one'):
                self.assertEqual(NS['main'](['delete-account', 'one']), 0)
            self.assertEqual(set(NS['tomllib'].loads(config.read_text())['accounts']), {'two'})
            backups = list(root.glob('config.toml.backup-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), original)
            for path in [config, *backups]:
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)

    def test_cancel_does_not_modify_or_backup(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / 'config.toml'
            original = '[accounts.one]\nemail="one@example.test"\n'
            config.write_text(original)
            with self.environment(root, config, 'no'):
                self.assertEqual(NS['main'](['delete-account', 'one']), 0)
            self.assertEqual(config.read_text(), original)
            self.assertEqual(list(root.glob('*.backup-*')), [])

    def test_add_delegates_to_native_wizard(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / 'config.toml'
            with self.environment(root, config), patch.dict(GLOBALS, native=unittest.mock.Mock(return_value=0)):
                self.assertEqual(NS['main'](['add-account']), 0)
                GLOBALS['native'].assert_called_once_with('--config', str(config), 'configure')
            self.assertFalse(config.exists())

    def test_list_and_check_delegate_without_interactive_prompts(self):
        with patch.dict(GLOBALS, native=unittest.mock.Mock(return_value=0)):
            self.assertEqual(NS['main'](['list-accounts']), 0)
            GLOBALS['native'].assert_called_with('account', 'list')
            self.assertEqual(NS['main'](['check-account', 'one']), 0)
            GLOBALS['native'].assert_called_with('--account', 'one', 'account', 'check')

    def test_multiple_overlay_mutation_refused(self):
        with patch.dict(os.environ, HIMALAYA_CONFIG='/private/base.toml:/private/extra.toml'):
            with self.assertRaises(ValueError):
                NS['config_path']()

    def test_symlink_into_git_checkout_refused(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            checkout = root / 'checkout'
            checkout.mkdir()
            subprocess.run(['git', 'init', '-q', str(checkout)], check=True)
            config = checkout / 'config.toml'
            config.write_text('')
            link = root / 'config-link'
            link.symlink_to(config)
            with self.assertRaises(ValueError):
                NS['private_path'](link)

    def test_login_prepares_private_helper_settings_and_delegates(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / 'config.toml'
            with self.environment(root, config), patch('builtins.input', side_effect=[
                '00000000-0000-0000-0000-000000000000', 'common'
            ]), patch('subprocess.call', return_value=0) as call:
                self.assertEqual(NS['main'](['login', 'fixture']), 0)
            settings = root / 'himalaya/oauth.json'
            self.assertEqual(json.loads(settings.read_text())['fixture']['tenant_id'], 'common')
            self.assertEqual(settings.stat().st_mode & 0o777, 0o600)
            self.assertEqual(call.call_args.args[0][-2:], ['fixture', '--login'])

    def test_noninteractive_mutation_refused(self):
        with patch('sys.stdin.isatty', return_value=False), redirect_stderr(io.StringIO()):
            self.assertEqual(NS['main'](['add-account']), 1)


if __name__ == '__main__':
    unittest.main()
