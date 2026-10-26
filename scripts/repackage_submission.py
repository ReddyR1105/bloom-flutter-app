"""Rebuild the submission ZIP and manifest after genuine evidence is added.

Standard-library only. It verifies bytes/CRC, not signatures, course compliance,
peer participation or the truth of added evidence. It never uploads anything.
"""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--package', type=Path, default=Path(__file__).resolve().parent)
    args = parser.parse_args()
    root = args.package.resolve()
    required = ['app-release.apk', 'Bloom_Source.zip', 'PROJECT_REPORT.pdf',
                'Project1_Presentation.pptx', 'TEST_LOG.md', 'AI_FEATURE.md',
                'HUMAN_INPUT_REQUIRED.md']
    for name in required:
        if not (root/name).is_file():
            raise SystemExit(f'Missing technical artifact: {name}')
    metadata_path = root/'PACKAGE_METADATA.json'
    metadata = json.loads(metadata_path.read_text(encoding='utf-8-sig')) if metadata_path.exists() else {}
    files = []
    for path in sorted(root.rglob('*')):
        if path.is_file() and path.name != 'MANIFEST.json' and '__pycache__' not in path.parts:
            files.append({'path': path.relative_to(root).as_posix(), 'bytes': path.stat().st_size,
                          'sha256': hashlib.sha256(path.read_bytes()).hexdigest().upper()})
    (root/'MANIFEST.json').write_text(json.dumps({
        'source_snapshot': metadata.get('source_snapshot'),
        'human_evidence_complete': metadata.get('human_evidence_complete', False),
        'note': 'Hashes verify file integrity only, not authenticity or course compliance.',
        'files': files}, indent=2)+'\n', encoding='utf-8')
    destination = root.parent/(root.name+'.zip')
    with zipfile.ZipFile(destination, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(root.rglob('*')):
            if path.is_file() and '__pycache__' not in path.parts:
                archive.write(path, f'{root.name}/{path.relative_to(root).as_posix()}')
    with zipfile.ZipFile(destination) as archive:
        assert archive.testzip() is None, 'ZIP CRC failure'
        for file in files:
            assert hashlib.sha256(archive.read(f'{root.name}/{file["path"]}')).hexdigest().upper() == file['sha256'], file['path']
        count = len(archive.namelist())
    print(f'Verified ZIP: {destination}\nFiles: {count}\nBytes: {destination.stat().st_size}')
    print('SHA-256:', hashlib.sha256(destination.read_bytes()).hexdigest().upper())
    print('Integrity checks do not certify missing human evidence, signatures or course compliance.')


if __name__ == '__main__':
    main()
