"""Mail session tests; synthetic secret values only, no 1Password access."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import tomllib
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'common/.bin/nvim-mail-session'
NS = runpy.run_path(str(SCRIPT))


class MailSessionTests(unittest.TestCase):
    def test_recognizes_standard_secret_commands(self):
        for command in ['op read "op://Private/Mail/password"', ['op', 'read', '-n', 'op://Private/Mail/password']]:
            self.assertEqual(NS['op_reference'](command), 'op://Private/Mail/password')

    def test_keeps_dynamic_commands_and_otp_live(self):
        for command in ['op read op://Private/Mail/password && echo other', 'op read op://$VAULT/Mail/password',
                        'op read "op://Private/Mail/otp?attribute=otp"', 'op read --account other op://Private/Mail/password',
                        'some-other-command', 'op read "unclosed']:
            self.assertIsNone(NS['op_reference'](command))

    def test_deduplicates_passwords_and_leaves_tokens_live(self):
        data = {'accounts': {'fixture': {
            'imap': {'sasl': {'plain': {'password': {'command': 'op read "op://Private/Mail/password"'}}}},
            'smtp': {'sasl': {'plain': {'password': {'command': ['op', 'read', 'op://Private/Mail/password']}}}},
            'msgraph': {'auth': {'token': {'command': ['nvim-mail-token', 'fixture']}}},
        }}}
        dotenv, overlay = NS['prepare'](data)
        self.assertEqual(len(dotenv.splitlines()), 1)
        parsed = tomllib.loads(overlay)['accounts']['fixture']
        self.assertEqual(parsed['imap']['sasl']['plain']['password']['command'], 'printenv DOTFILES_MAIL_PASSWORD_0')
        self.assertEqual(parsed['smtp']['sasl']['plain']['password']['command'], ['printenv', 'DOTFILES_MAIL_PASSWORD_0'])
        self.assertNotIn('msgraph', parsed)

    def test_native_wizard_passwd_spelling(self):
        data = {'accounts': {'fixture': {'imap': {'sasl': {'plain': {'passwd': {
            'command': 'op read "op://Private/Mail/password"'
        }}}}}}}
        dotenv, overlay = NS['prepare'](data)
        self.assertEqual(len(dotenv.splitlines()), 1)
        self.assertIn('passwd', tomllib.loads(overlay)['accounts']['fixture']['imap']['sasl']['plain'])

    def test_no_passwords_needs_no_op_run(self):
        self.assertEqual(NS['prepare']({'accounts': {'fixture': {'maildir': {'root': '/synthetic'}}}}), ('', ''))

    def test_overlays_merge(self):
        data = {'accounts': {'fixture': {'email': 'synthetic@example.test', 'default': True}}}
        NS['merge'](data, {'accounts': {'fixture': {'default': False}}})
        self.assertEqual(data['accounts']['fixture'], {'email': 'synthetic@example.test', 'default': False})

    def test_native_op_run_once_and_no_password_files(self):
        with tempfile.TemporaryDirectory(prefix='mail-session-test-') as directory:
            root = Path(directory)
            config = root / 'config.toml'
            config.write_text('[accounts.fixture]\nimap.sasl.plain.password.command = "op read op://Private/Mail/password"\n')
            marker = root / 'op-calls'
            fake_op = root / 'op'
            fake_op.write_text('''#!/usr/bin/env python3
import json,os,subprocess,sys
from pathlib import Path
args=sys.argv[1:]
assert args[:2]==['run','--no-masking']
source=Path(args[args.index('--env-file')+1])
config=Path(os.environ['HIMALAYA_CONFIG'].split(':')[-1])
assert source.stat().st_mode & 0o777 == 0o600
assert config.stat().st_mode & 0o777 == 0o600
assert source.parent.stat().st_mode & 0o777 == 0o700
assert 'synthetic-test-password' not in source.read_text()+config.read_text()
env=dict(os.environ)
for line in source.read_text().splitlines():
 key,value=line.split('=',1);assert json.loads(value).startswith('op://');env[key]='synthetic-test-password'
Path(os.environ['TEST_OP_CALLS']).write_text('one invocation')
sys.exit(subprocess.call(args[args.index('--')+1:],env=env))
''')
            fake_op.chmod(0o755)
            child = root / 'child.py'
            child.write_text('''import os,shlex,subprocess,tomllib
from pathlib import Path
original,overlay=os.environ['HIMALAYA_CONFIG'].split(':')
assert Path(original).read_text().startswith('[accounts.fixture]')
command=tomllib.loads(Path(overlay).read_text())['accounts']['fixture']['imap']['sasl']['plain']['password']['command']
if isinstance(command,str):command=shlex.split(command)
for _ in range(3):
 assert subprocess.check_output(command,text=True).strip()=='synthetic-test-password'
''')
            env = dict(os.environ, PATH=str(root)+':'+os.environ['PATH'], HIMALAYA_CONFIG=str(config), TEST_OP_CALLS=str(marker))
            result = subprocess.run([str(SCRIPT), 'python3', str(child)], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(marker.read_text(), 'one invocation')
            self.assertNotIn('synthetic-test-password', result.stdout+result.stderr)
            self.assertIn('op read', config.read_text())


if __name__ == '__main__':
    unittest.main()
