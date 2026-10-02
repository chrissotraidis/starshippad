#!/usr/bin/env python3
"""Offline patch replay against local pinned Git archives; no clone or reset."""
import hashlib
import io
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASELINE_REVISION = '57ced908a969290bc48b4eea347cf7f7a289389f'
LUS = ROOT / 'sources/Starship/libultraship'
SDL = ROOT / 'build-ios/_deps/sdl2-src'
WORK = ROOT / 'build-uikit-tests'
WORK.mkdir(exist_ok=True)
RUN = Path(tempfile.mkdtemp(prefix='replay-', dir=WORK))
ORIGINAL = RUN / 'baseline'
for relative in ['patches/libultraship-ios.patch', 'patches/starship-ios.patch',
                 'patches/torch-ios.patch', 'scripts/apply-source-patches.sh']:
    destination = ORIGINAL / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(subprocess.check_output(
        ['git', '-C', str(ROOT), 'show', BASELINE_REVISION + ':' + relative]))


def run(args, cwd, success=True):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    return result.stdout


def snapshot(tree):
    return {str(p.relative_to(tree)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in tree.rglob('*') if p.is_file() and '.git' not in p.parts}


def archive(repo, destination, paths):
    destination.mkdir(parents=True, exist_ok=True)
    payload = subprocess.check_output(['git', '-C', str(repo), 'archive', 'HEAD', *paths])
    with tarfile.open(fileobj=io.BytesIO(payload)) as source:
        for member in source.getmembers():
            assert member.isfile() or member.isdir(), member.name
            assert not Path(member.name).is_absolute() and '..' not in Path(member.name).parts
        source.extractall(destination)
    run(['git', 'init', '-q'], destination)
    run(['git', 'add', '--all'], destination)
    run(['git', '-c', 'user.name=SDL patch fixture', '-c', 'user.email=fixture@example.invalid',
         '-c', 'commit.gpgsign=false', '-c', 'core.hooksPath=/dev/null',
         'commit', '-qm', 'Local pinned source fixture'], destination)


def patch_paths(patch, repo):
    changed = [line.split('\t')[-1] for line in run(['git', 'apply', '--numstat', str(patch)], ROOT).splitlines()]
    existing = set(run(['git', 'ls-files'], repo).splitlines())
    return [path for path in changed if path in existing]


def prepared(name, legacy):
    fixture = RUN / name
    fixture.mkdir()
    shutil.copytree(ROOT / 'scripts', fixture / 'scripts')
    shutil.copytree(ROOT / 'patches', fixture / 'patches')
    shutil.copytree(ROOT / 'ios-assets', fixture / 'ios-assets')
    for relative, patch in [('sources/Starship', 'starship-ios.patch'),
                            ('sources/Starship/libultraship', 'libultraship-ios.patch'),
                            ('sources/Starship/tools/Torch', 'torch-ios.patch')]:
        repo = ROOT / relative
        archive(repo, fixture / relative, patch_paths(ROOT / 'patches' / patch, repo))
    if legacy:
        shutil.copytree(ORIGINAL / 'patches', fixture / 'patches', dirs_exist_ok=True)
        shutil.copy2(ORIGINAL / 'scripts/apply-source-patches.sh', fixture / 'scripts/apply-source-patches.sh')
        run(['bash', 'scripts/apply-source-patches.sh'], fixture)
        shutil.copytree(ROOT / 'patches', fixture / 'patches', dirs_exist_ok=True)
        shutil.copy2(ROOT / 'scripts/apply-source-patches.sh', fixture / 'scripts/apply-source-patches.sh')
    return fixture


for legacy in [False, True]:
    fixture = prepared('legacy' if legacy else 'pristine', legacy)
    lus = fixture / 'sources/Starship/libultraship'
    edit = lus / 'src/Context.cpp'
    edit.write_text(edit.read_text() + '\n// unrelated local edit retained by replay test\n')
    marker = fixture / 'sources/Starship/local-edit.txt'
    marker.write_text('untracked edit stays\n')
    output = run(['bash', 'scripts/apply-source-patches.sh'], fixture)
    if legacy:
        assert 'Upgraded: libultraship-ios.patch' in output
        assert 'Upgraded: starship-ios.patch' in output
    first = snapshot(fixture / 'sources')
    run(['bash', 'scripts/apply-source-patches.sh'], fixture)
    assert snapshot(fixture / 'sources') == first
    assert edit.read_text().endswith('// unrelated local edit retained by replay test\n')
    assert marker.read_text() == 'untracked edit stays\n'
    print(('legacy upgrade' if legacy else 'pristine wrapper') + ': PASS, rerun identical, edits preserved')

fixture = prepared('wrapper-conflict', True)
conflict = fixture / 'sources/Starship/libultraship/cmake/dependencies/ios.cmake'
conflict.write_text(conflict.read_text().replace('5d249570393f7a37e037abf22cd6012a4cc56a71', 'local-edit-kept'))
before = snapshot(fixture / 'sources')
run(['bash', 'scripts/apply-source-patches.sh'], fixture, success=False)
assert snapshot(fixture / 'sources') == before
print('incompatible wrapper edit: PASS, fails without changing sources')

helper = LUS / 'cmake/dependencies/git-patch.cmake'
complete = LUS / 'cmake/dependencies/patches/sdl2-uikit-scenes.patch'
followup = LUS / 'cmake/dependencies/patches/sdl2-uikit-orientation.patch'
patch_files = patch_paths(complete, SDL)
for state in ['pristine', 'scene-only', 'complete', 'conflict']:
    tree = RUN / ('sdl-' + state)
    archive(SDL, tree, patch_files + ['src/SDL.c'])
    if state in ['scene-only', 'complete']:
        run(['git', 'apply', str(complete)], tree)
    if state == 'scene-only':
        run(['git', 'apply', '--reverse', str(followup)], tree)
    edit = tree / 'src/SDL.c'
    edit.write_text(edit.read_text() + '\n/* unrelated local edit kept */\n')
    if state == 'conflict':
        conflict = tree / 'src/video/uikit/SDL_uikitwindow.m'
        conflict.write_text(conflict.read_text().replace('initWithFrame:data.uiscreen.bounds', 'initWithFrame:local_edit'))
    command = ['cmake', '-Dpatch_file=' + str(complete), '-Dfallback_patch_file=' + str(followup),
               '-Dwith_reset=TRUE', '-P', str(helper)]
    before = snapshot(tree)
    run(command, tree, success=state != 'conflict')
    if state == 'conflict':
        assert snapshot(tree) == before
    else:
        run(['git', 'apply', '--reverse', '--check', str(complete)], tree)
        first = snapshot(tree)
        run(command, tree)
        assert snapshot(tree) == first
    assert edit.read_text().endswith('/* unrelated local edit kept */\n')
    print('SDL ' + state + ': PASS, no reset, edits preserved')

print('Retained offline fixtures:', RUN)
