#!/usr/bin/env python3
import argparse
from pathlib import Path
import tomli
import subprocess


def get_version(toml_path):
    with open(toml_path, 'rb') as f:
        data = tomli.load(f)
        return data['package']['version']


def update_readme(readme_path, version):
    with open(readme_path, 'r') as f:
        md = f.read()

    md = md.replace('{{VERSION}}', version)
    md = md.replace('badge/dev-manual.pdf-orange', f'badge/v{version}-manual.pdf-green')
    md = md.replace('/releases/download/latest/', f'/releases/download/v{version}/')

    with open(readme_path, 'w') as f:
        f.write(md)

    print(f"Updated {readme_path.name}")

def compile_manual(source_url):
  subprocess.run([
    "typst",
    "compile",
    "../docs/manual.typ",
    "--input", f"source-url={source_url}",
    "--root", ".."
  ])

  print(f"Compiled manual with links to {source_url}")


def main():
    parser = argparse.ArgumentParser(
        description='Replace placeholders in README.md and example files for release.'
    )
    parser.add_argument(
        '--root',
        type=Path,
        default=Path(__file__).parent.parent,
        help='Root directory of the project'
    )

    args = parser.parse_args()
    root = args.root

    # Parse version from typst.toml
    toml_path = root / 'typst.toml'
    version = get_version(toml_path)
    print(f"Prepare for release: {version}")

    # Update README.md
    readme_path = root / 'README.md'
    assert readme_path.exists(), f"README not found at {readme_path}"
    update_readme(readme_path, version)

    source_url = f"https://github.com/Jollywatt/typst-parsely/blob/v{version}"
    compile_manual(source_url)


if __name__ == '__main__':
    main()
