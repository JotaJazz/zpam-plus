#!/usr/bin/env python3
"""Checks the repository's Markdown documentation.

    python3 scripts/check_docs.py

It reports, as file:line: message,
  - relative links to files or headings that do not exist,
  - repository paths that do not exist, in backticks or in code blocks
    (a word counts as a path when its first folder exists in the repository),
  - personal data: /home and /mnt paths, Windows drive and WSL share paths,
    IP addresses, email addresses and keys (placeholders such as /home/<user>
    and <drive>:\\ are allowed, and so are loopback and documentation addresses
    and example or noreply emails),
  - stages of docs/ai/PROJECT_MEMORY.md with more than 3 bullets, a heading that
    is not "## YYYY-MM-DD — topic" with a real date, or that are not newest first.

Local files are skipped: CLAUDE.md, docs/superpowers, .claude, .superpowers,
.server (test server output), and docs/upstream, the zPAM 3.38 documentation
kept as it was written.
Tests: scripts/test_check_docs.py.
"""
import datetime, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {'.git', '.claude', '.superpowers', 'docs/superpowers', '.server', 'docs/upstream'}
SKIP_NAMES = {'CLAUDE.md'}
MEMORY = 'docs/ai/PROJECT_MEMORY.md'
# paths relative to the reader
SKIP_PREFIXES = ('./', '../')
MAX_STAGE_BULLETS = 3

FENCE = re.compile(r'^\s*(```|~~~)')
HEADING = re.compile(r'^(#{1,6})\s+(.*?)\s*#*\s*$')
LINK = re.compile(r'\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)')
CODE = re.compile(r'`([^`\n]+)`')
PERSONAL = [
    (re.compile(r'/home/(?!<)[\w.-]+'), 'home folder path'),
    (re.compile(r'/mnt/(?!<)[\w.-]+'), 'mount path'),
    (re.compile(r'(?<![\w<>])[A-Za-z]:[\\/]\\?\w'), 'Windows drive path'),
    (re.compile(r'\\\\wsl(?:\$|\.localhost)', re.I), 'WSL share path'),
    (re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'), 'private key'),
    (re.compile(r'\b(?:ghp|gho|ghs|github_pat)_[A-Za-z0-9_]{20,}'), 'GitHub token'),
    (re.compile(r'\bglpat-[A-Za-z0-9_-]{20,}'), 'GitLab token'),
    (re.compile(r'\bAKIA[0-9A-Z]{16}\b'), 'AWS key'),
]
EMAIL = re.compile(r'\b[\w.+-]+@([\w-]+(?:\.[\w-]+)+)\b')
ALLOWED_EMAIL = re.compile(r'(^|\.)(example\.(com|org|net)|noreply\.github\.com)$')
ALLOWED_EMAIL_USERS = ('noreply@',)
IP = re.compile(r'(?<![\d.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![\d.])')
ALLOWED_IPS = {'0.0.0.0', '255.255.255.255'}
# loopback and the documentation ranges of RFC 5737
ALLOWED_IP_PREFIXES = ('127.', '192.0.2.', '198.51.100.', '203.0.113.')
STAGE = re.compile(r'^## (\d{4}-\d{2}-\d{2}) — \S')
BULLET = re.compile(r'^(?:[-*+]|\d+[.)])\s')


def doc_files(root):
    found = []
    for dirpath, dirnames, filenames in os.walk(root):
        rel_dir = os.path.relpath(dirpath, root).replace(os.sep, '/')
        rel_dir = '' if rel_dir == '.' else rel_dir + '/'
        dirnames[:] = [d for d in dirnames if rel_dir + d not in SKIP_DIRS]
        for name in filenames:
            if name.endswith('.md') and name not in SKIP_NAMES:
                found.append(rel_dir + name)
    return sorted(found)


def read_lines(path):
    with open(path, encoding='utf-8') as f:
        return f.read().splitlines()


def lines_with_code_state(lines):
    """Yields (line number, line, inside a fenced block) for each line except the fences."""
    in_code = False
    for lineno, line in enumerate(lines, 1):
        if FENCE.match(line):
            in_code = not in_code
            continue
        yield lineno, line, in_code


def slug(text):
    # GitHub's heading anchors: lower case, punctuation dropped, spaces to hyphens
    text = re.sub(r'`|\*\*|__', '', text).strip().lower()
    return re.sub(r'[^\w\- ]', '', text).replace(' ', '-')


def anchors(lines):
    seen = {}
    for _, line, in_code in lines_with_code_state(lines):
        m = HEADING.match(line)
        if m and not in_code:
            base = slug(m.group(2))
            count = seen.get(base, 0)
            seen[base] = count + 1
            yield base if count == 0 else f'{base}-{count}'


def is_repo_path(root, word):
    if '/' not in word or word.startswith(SKIP_PREFIXES):
        return False
    if re.search(r'[*<>{}$?=~|"\'\\]', word) or word.startswith('-'):
        return False
    first = word.split('/', 1)[0]
    return first != '' and os.path.exists(os.path.join(root, first))


def check_personal(lineno, line):
    found = [(lineno, f'personal data ({what}): {m.group(0)}')
        for pattern, what in PERSONAL for m in pattern.finditer(line)]
    for m in IP.finditer(line):
        ip = m.group(0)
        if all(int(part) <= 255 for part in m.groups()) and ip not in ALLOWED_IPS \
                and not ip.startswith(ALLOWED_IP_PREFIXES):
            found.append((lineno, f'personal data (IP address): {ip}'))
    for m in EMAIL.finditer(line):
        if not ALLOWED_EMAIL.search(m.group(1).lower()) and not m.group(0).lower().startswith(ALLOWED_EMAIL_USERS):
            found.append((lineno, f'personal data (email address): {m.group(0)}'))
    return found


def check_memory(lines):
    found = []
    stage, bullets, previous = None, 0, None

    def close():
        if stage is not None and bullets > MAX_STAGE_BULLETS:
            found.append((stage, f'memory stage has {bullets} bullets (at most {MAX_STAGE_BULLETS})'))

    for lineno, line, in_code in lines_with_code_state(lines):
        if in_code:
            continue
        if line.startswith('## '):
            close()
            stage, bullets = lineno, 0
            m = STAGE.match(line)
            try:
                if m:
                    datetime.date.fromisoformat(m.group(1))
            except ValueError:
                m = None
            if not m:
                found.append((lineno, 'memory stage heading must be "## YYYY-MM-DD — topic" with a real date'))
                continue
            if previous is not None and m.group(1) > previous:
                found.append((lineno, 'memory stages must be newest first'))
            previous = m.group(1)
        elif stage is not None and BULLET.match(line):
            bullets += 1
    close()
    return found


class Checker:
    def __init__(self, root):
        self.root = root
        self.anchor_cache = {}

    def anchors_of(self, path):
        if path not in self.anchor_cache:
            try:
                self.anchor_cache[path] = set(anchors(read_lines(path)))
            except (OSError, UnicodeDecodeError):
                self.anchor_cache[path] = set()
        return self.anchor_cache[path]

    def check_links(self, rel, lineno, line):
        found = []
        here = os.path.join(self.root, rel)
        for target in LINK.findall(CODE.sub('', line)):
            if re.match(r'[a-z][a-z0-9+.-]*:', target):
                continue
            path, _, anchor = target.partition('#')
            path = os.path.normpath(os.path.join(os.path.dirname(here), path)) if path else here
            if not os.path.exists(path):
                found.append((lineno, f'broken link: {target}'))
            elif anchor and path.endswith('.md') and anchor.lower() not in self.anchors_of(path):
                found.append((lineno, f'broken anchor: {target}'))
        return found

    def check_paths(self, lineno, text):
        found = []
        for word in text.split():
            path = re.sub(r':\d+(?:-\d+)?$', '', word.strip('`,;:()[]'))
            if is_repo_path(self.root, path) and not os.path.exists(os.path.join(self.root, path.rstrip('/'))):
                found.append((lineno, f'path does not exist: {path}'))
        return found

    def check_file(self, rel):
        try:
            lines = read_lines(os.path.join(self.root, rel))
        except UnicodeDecodeError:
            return [(1, 'file is not UTF-8')]
        found = []
        for lineno, line, in_code in lines_with_code_state(lines):
            if in_code:
                found += self.check_paths(lineno, line)
            else:
                found += self.check_links(rel, lineno, line)
                for token in CODE.findall(line):
                    found += self.check_paths(lineno, token)
            found += check_personal(lineno, line)
        if rel == MEMORY:
            found += check_memory(lines)
        return sorted(found)


def check_file(root, rel):
    return Checker(root).check_file(rel)


def main():
    checker = Checker(ROOT)
    problems = 0
    for rel in doc_files(ROOT):
        for lineno, message in checker.check_file(rel):
            print(f'{rel}:{lineno}: {message}')
            problems += 1
    if problems:
        sys.exit(f'{problems} problem(s) found')
    print('Documentation OK')


if __name__ == '__main__':
    main()
