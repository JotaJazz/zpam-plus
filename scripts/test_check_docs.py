#!/usr/bin/env python3
"""Tests for check_docs.py:

    python3 -m unittest discover -s scripts -p 'test_*.py'

The samples use placeholder names and documentation addresses, except one
private address that must trigger the IP check.
"""
import os, tempfile, textwrap, unittest

import check_docs


class CheckDocsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = self.tmp.name
        self.write('source/maps/mp/gametypes/sd.gsc', '')
        self.write('scripts/smoke_test.py', '')

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, rel, text):
        path = os.path.join(self.root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(textwrap.dedent(text))

    def check(self, rel, text):
        self.write(rel, text)
        return check_docs.check_file(self.root, rel)

    def messages(self, rel, text):
        return [m for _, m in self.check(rel, text)]

    # relative links

    def test_link_to_existing_file(self):
        self.write('docs/a.md', '')
        self.assertEqual(self.check('docs/b.md', '[a](a.md) [up](../scripts/smoke_test.py)\n'), [])

    def test_broken_link(self):
        found = self.check('docs/b.md', 'text\n[a](missing.md#part)\n')
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0][0], 2)
        self.assertIn('missing.md', found[0][1])

    def test_link_anchor_to_existing_heading(self):
        self.write('docs/a.md', '# Title\n\n## Doc-sync rules\n\n## Doc-sync rules\n')
        text = '## Local part\n\n[a](a.md#doc-sync-rules) [b](a.md#doc-sync-rules-1) [c](#local-part)\n'
        self.assertEqual(self.check('docs/b.md', text), [])

    def test_link_anchor_to_missing_heading(self):
        self.write('docs/a.md', '# Title\n')
        found = self.messages('docs/b.md', '[a](a.md#gone) [b](#nowhere)\n')
        self.assertEqual(len(found), 2)

    def test_headings_in_code_blocks_are_not_anchors(self):
        self.write('docs/a.md', '```\n# not a heading\n```\n')
        self.assertEqual(len(self.check('docs/b.md', '[a](a.md#not-a-heading)\n')), 1)

    def test_external_links_are_ignored(self):
        self.assertEqual(self.check('a.md', '[x](https://example.com/a.md) [m](mailto:a@example.com)\n'), [])

    def test_links_in_code_blocks_are_ignored(self):
        self.assertEqual(self.check('a.md', '```\n[a](missing.md)\n```\n'), [])
        self.assertEqual(self.check('a.md', '~~~\n[a](missing.md)\n~~~\n'), [])

    # paths in backticks

    def test_existing_backtick_path(self):
        self.assertEqual(self.check('a.md', 'see `source/maps/mp/gametypes/sd.gsc` and `scripts/`\n'), [])

    def test_missing_backtick_path(self):
        found = self.messages('a.md', 'see `source/maps/mp/gametypes/gone.gsc`\n')
        self.assertEqual(len(found), 1)
        self.assertIn('source/maps/mp/gametypes/gone.gsc', found[0])

    def test_backtick_path_with_line_number(self):
        self.assertEqual(self.check('a.md', '`source/maps/mp/gametypes/sd.gsc:120`\n'), [])

    def test_path_followed_by_punctuation(self):
        self.assertEqual(self.check('a.md', '```\nSV_X   source/maps/mp/gametypes/sd.gsc: notes\n```\n'), [])

    def test_backtick_placeholders_and_globs_are_ignored(self):
        text = '`source/maps/*.gsc` `scripts/<name>.py` `source/{a,b}`\n'
        self.assertEqual(self.check('a.md', text), [])

    def test_paths_relative_to_the_current_folder_are_ignored(self):
        self.assertEqual(self.check('a.md', '`./iniciar_cod2rev.sh` `../CoD2/main`\n'), [])

    def test_backtick_text_that_is_not_a_repo_path(self):
        self.assertEqual(self.check('a.md', '`maps/mp/bots/_bots.gsc` `a/b` `make PROTOCOL=118`\n'), [])

    def test_paths_in_commands_are_checked(self):
        self.assertEqual(len(self.check('a.md', '`python3 scripts/gone.py <game>`\n')), 1)
        self.assertEqual(len(self.check('a.md', '```bash\npython3 scripts/gone.py /path/to/CoD2\n```\n')), 1)
        self.assertEqual(self.check('a.md', '`python3 scripts/smoke_test.py --binary <bin>`\n'), [])

    def test_command_words_that_are_not_paths(self):
        self.assertEqual(self.check('a.md', '```\nmake OBJ_ROOT=x/obj CFLAGS="-m32 -DX=1"\n```\n'), [])

    # personal data

    def test_home_and_mnt_paths(self):
        found = self.messages('a.md', 'in /home/alice/x and /mnt/x/Games\n')
        self.assertEqual(len(found), 2)

    def test_placeholder_paths_are_allowed(self):
        self.assertEqual(self.check('a.md', '/home/<user>/x /mnt/<drive>/Games <drive>:\\Games\n'), [])

    def test_windows_drive_path(self):
        found = self.messages('a.md', 'installed in Q:\\Games\\x and Q:/Users/x\n')
        self.assertEqual(len(found), 2)

    def test_wsl_share_path(self):
        self.assertEqual(len(self.check('a.md', 'open \\\\wsl$\\Ubuntu\\x\n')), 1)

    def test_email_addresses(self):
        self.assertEqual(len(self.check('a.md', 'mail alice@mail.test\n')), 1)
        self.assertEqual(self.check('a.md', 'a@example.com noreply@anthropic.com x@users.noreply.github.com\n'), [])

    def test_ip_addresses(self):
        found = self.messages('a.md', 'server at 10.20.30.40:28960\n')
        self.assertEqual(len(found), 1)

    def test_allowed_ip_addresses(self):
        text = '127.0.0.1 0.0.0.0 255.255.255.255 192.0.2.10 198.51.100.7 203.0.113.99\n'
        self.assertEqual(self.check('a.md', text), [])

    def test_version_numbers_are_not_ips(self):
        self.assertEqual(self.check('a.md', 'mbedTLS 3.6.7 and 1.2.3.4.5\n'), [])

    def test_keys(self):
        found = self.messages('a.md', '-----BEGIN RSA PRIVATE KEY-----\ntoken ghp_abcdefghijklmnopqrstuvwxyz0123456789\n')
        self.assertEqual(len(found), 2)

    # project memory

    MEMORY = 'docs/ai/PROJECT_MEMORY.md'

    def test_memory_stage_with_three_bullets(self):
        text = '# Memory\n\n## 2026-10-02 — b\n\n- 1\n- 2\n  - nested\n- 3\n\n## 2026-10-01 — a\n\n- 1\n'
        self.assertEqual(self.check(self.MEMORY, text), [])

    def test_memory_stage_with_four_bullets(self):
        found = self.check(self.MEMORY, '# Memory\n\n## 2026-10-01 — a\n\n- 1\n- 2\n- 3\n- 4\n')
        self.assertEqual(len(found), 1)
        self.assertEqual(found[0][0], 3)

    def test_memory_counts_every_bullet_style(self):
        found = self.check(self.MEMORY, '# Memory\n\n## 2026-10-01 — a\n\n* 1\n+ 2\n1. 3\n- 4\n')
        self.assertEqual(len(found), 1)

    def test_memory_ignores_code_blocks(self):
        text = '# Memory\n\n```\n## YYYY-MM-DD — topic\n- 1\n```\n\n## 2026-10-01 — a\n\n- 1\n'
        self.assertEqual(self.check(self.MEMORY, text), [])

    def test_memory_stage_date_must_exist(self):
        self.assertEqual(len(self.check(self.MEMORY, '# Memory\n\n## 2026-13-40 — a\n\n- 1\n')), 1)

    def test_memory_stage_heading_format(self):
        found = self.messages(self.MEMORY, '# Memory\n\n## October 1 — a\n\n- 1\n')
        self.assertEqual(len(found), 1)

    def test_memory_stages_newest_first(self):
        found = self.messages(self.MEMORY, '# Memory\n\n## 2026-10-01 — a\n\n- 1\n\n## 2026-10-02 — b\n\n- 1\n')
        self.assertEqual(len(found), 1)
        self.assertIn('newest', found[0])

    def test_bullet_rule_only_applies_to_memory(self):
        self.assertEqual(self.check('docs/other.md', '## 2026-10-01 — a\n\n- 1\n- 2\n- 3\n- 4\n'), [])

    # which files are scanned

    def test_file_that_is_not_utf8(self):
        path = os.path.join(self.root, 'bad.md')
        with open(path, 'wb') as f:
            f.write(b'caf\xe9\n')
        found = check_docs.check_file(self.root, 'bad.md')
        self.assertEqual(len(found), 1)
        self.assertIn('UTF-8', found[0][1])

    def test_doc_files_skip_local_and_upstream(self):
        for rel in ('README.md', 'AGENTS.md', 'docs/a.md', 'docs/superpowers/plan.md',
                    'CLAUDE.md', 'docs/upstream/zpam-3.38.md', '.server/main/x.md', '.claude/x.md'):
            self.write(rel, '')
        self.assertEqual(check_docs.doc_files(self.root), ['AGENTS.md', 'README.md', 'docs/a.md'])


if __name__ == '__main__':
    unittest.main()
