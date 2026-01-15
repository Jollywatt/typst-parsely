#!/usr/bin/env python3
"""
Find all typst element definitions and find their field types (positional, variadic, named).

Outputs "content-positional-args.json".

This script expects to be run at the root of git@github.com:typst/typst.git.
"""

import argparse
import json
from pathlib import Path
from typing import Optional
import tree_sitter_rust as tsrust
from tree_sitter import Language, Parser


# Elements to exclude from the output
EXCLUDED = {
    "counter-update",
    "layout",
    "cite-group",
    "counter-display",
    "link-marker",
    "state-update",
    "bibliography",
    "cite",
    "csl-light",
    "terms",
    "direct-link",
    "context",
    "elem",
    "cubic",
    "line",
    "artifact",
    "pdf-marker-tag",
    "par-line-marker",
    "frame",
    "csl-indent",
    "prefix-info",
}


def derive_elem_name(struct_name: str) -> str:
    """Convert struct name to element name (remove Elem suffix, CamelCase to kebab-case)."""
    name = struct_name.removesuffix("Elem")
    result = []
    for i, ch in enumerate(name):
        if ch.isupper() and i > 0:
            result.append('-')
        result.append(ch.lower())
    return ''.join(result)


def find_child(node, node_type: str):
    """Find first child node of given type."""
    return next((child for child in node.children if child.type == node_type), None)


def get_text(node) -> str:
    """Get decoded text from a node."""
    return node.text.decode('utf-8') if node else ""


def matches(nodes, *patterns) -> bool:
    """Check if sequence of nodes matches given leading pattern(s)."""
    if type(nodes) is not list: nodes = [nodes]
    if len(nodes) < len(patterns):
        return False
    
    for node, pattern in zip(nodes, patterns):
        if not node:
            return False
        if 'type' in pattern and node.type != pattern['type']:
            return False
        if 'text' in pattern and get_text(node) != pattern['text']:
            return False
    
    return True


def get_attribute_identifier(attr_node) -> Optional[str]:
    """Get the identifier from an attribute_item node (e.g., 'elem', 'positional', 'required')."""
    attribute = find_child(attr_node, "attribute")
    identifier = find_child(attribute, "identifier") if attribute else None
    return get_text(identifier) if identifier else None


def extract_name_from_attr(attr_node) -> Optional[str]:
    """Extract name from #[elem(name = "...")] attribute node.
    
    Matches AST pattern: attribute → token_tree → (identifier:"name", =, string_literal)
    """
    attribute = find_child(attr_node, "attribute")
    if not attribute:
        return None
    
    token_tree = find_child(attribute, "token_tree")
    if not token_tree:
        return None
    
    # Look for pattern: identifier="name", =, string_literal
    children = list(token_tree.children)
    for i, child in enumerate(children):
        if matches(children[i:], {"type": "identifier", "text": "name"}, {"type": "="}, {"type": "string_literal"}):
            string_content = find_child(children[i+2], "string_content")
            if string_content:
                return get_text(string_content)
    
    return None


def get_preceding_attributes(siblings, index: int):
    """Get all attribute_item nodes immediately preceding the given index."""
    attrs = []
    i = index - 1
    while i >= 0 and siblings[i].type in ["attribute_item", "line_comment"]:
        if matches(siblings[i], {"type": "attribute_item"}):
            attrs.append(siblings[i])
        i -= 1
    return attrs


def extract_elem_from_struct(struct_node, elem_attr_node) -> Optional[tuple]:
    """Extract element info from a struct_item node."""
    type_id = find_child(struct_node, "type_identifier")
    if not type_id:
        return None
    
    struct_name = get_text(type_id)
    elem_name = extract_name_from_attr(elem_attr_node) or derive_elem_name(struct_name)
    
    if elem_name in EXCLUDED:
        return None
    
    field_list = find_child(struct_node, "field_declaration_list")
    if not field_list:
        return None
    
    # Extract fields with their attributes
    positional = []
    variadic = None
    
    children = field_list.children
    for i, field in enumerate(children):
        if not matches(field, {"type": "field_declaration"}):
            continue
        
        field_id = find_child(field, "field_identifier")
        if not field_id:
            continue
        
        field_name = get_text(field_id)
        attrs = get_preceding_attributes(children, i)
        attr_names = {get_attribute_identifier(attr) for attr in attrs}
        
        if "required" in attr_names or "positional" in attr_names:
            positional.append(field_name)
        if "variadic" in attr_names:
            variadic = field_name
    
    elem_info = {}
    if positional:
        elem_info["positional"] = positional
    if variadic:
        elem_info["variadic"] = variadic
    
    return (elem_name, elem_info)


def extract_from_file(file_path: Path, parser: Parser) -> dict:
    """Extract all elem definitions from a Rust file."""
    try:
        content = file_path.read_bytes()
        tree = parser.parse(content)
        
        result = {}
        children = tree.root_node.children
        
        for i in range(len(children) - 1):
            if matches(children[i:], {"type": "attribute_item"}, {"type": "struct_item"}):
                attr_node, struct_node = children[i:i+2]
                if get_attribute_identifier(attr_node) == "elem":
                    elem_info = extract_elem_from_struct(struct_node, attr_node)
                    if elem_info:
                        result[elem_info[0]] = elem_info[1]
        
        return result
    
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        import traceback
        traceback.print_exc()
        return {}


def main():
    # Parse command line arguments
    parser_arg = argparse.ArgumentParser(description="Extract element definitions from Typst repo")
    parser_arg.add_argument("typst_repo", type=Path, help="Path to the typst repository")
    args = parser_arg.parse_args()
    
    typst_repo = args.typst_repo
    if not typst_repo.exists():
        print(f"Error: Path does not exist: {typst_repo}")
        return
    
    # Setup tree-sitter parser
    parser = Parser(Language(tsrust.language()))
    
    # Find all Rust files
    crates_dir = typst_repo / "crates"
    if not crates_dir.exists():
        print(f"Error: crates directory not found at {crates_dir}")
        return
    
    rust_files = list(crates_dir.rglob("*.rs"))
    print(f"Found {len(rust_files)} Rust files")
    
    # Extract from all files
    result = {}
    for rust_file in rust_files:
        file_result = extract_from_file(rust_file, parser)
        result.update(file_result)
    
    print(f"Found {len(result)} elem definitions")
    
    # Write output
    output_file = Path(__file__).parent.parent / "src" / "content-positional-args.json"
    output_file.write_text(json.dumps(result, indent=2))
    print(f"JSON written to: {output_file}")


if __name__ == "__main__":
    main()
