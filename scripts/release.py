#!/usr/bin/env python3
import argparse
from pathlib import Path
import tomli


def get_version(toml_path):
    with open(toml_path, 'rb') as f:
        data = tomli.load(f)
        return data['package']['version']


def update_readme(readme_path, version):
    with open(readme_path, 'r') as f:
        md = f.read()
    
    md = md.replace('{{VERSION}}', version)
    md = md.replace('badge/dev-manual.pdf-orange', f'badge/v{version}-manual.pdf-green')
    md = md.replace('/releases/download/main/', f'/releases/download/v{version}/')

    with open(readme_path, 'w') as f:
        f.write(md)
    
    print(f"Updated {readme_path.name}")


def update_example_files(examples_dir, version):
    """Replace import statement in .typ example files."""
    old_import = '#import "../../src/exports.typ" as parsely'
    new_import = f'#import "@preview/parsely:{version}"'
    
    typ_files = list(Path(examples_dir).rglob('*.typ'))
    
    for typ_file in typ_files:
        with open(typ_file, 'r') as f:
            md = f.read()
        
        # Only replace if the pattern is found at the start
        lines = md.split('\n')
        if lines and lines[0].strip() == old_import:
            lines[0] = new_import
            updated = '\n'.join(lines)
            
            with open(typ_file, 'w') as f:
                f.write(updated)
            
            print(f"Updated {typ_file.name}")


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
    
    # Update example files
    examples_dir = root / 'docs' / 'examples'
    assert examples_dir.exists(), f"examples directory not found at {examples_dir}"
    update_example_files(examples_dir, version)


if __name__ == '__main__':
    main()
