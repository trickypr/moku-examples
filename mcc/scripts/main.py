"""
Example indexer
- Collects information about examples for MCC
- Generates lints / warnings about example structure
"""

import json
import os
import sys
from pathlib import Path

from examples import Example, read_examples_from_directory


if not sys.argv[1]:
    print(f"Usage: python {sys.argv[0]} [path_to_examples]")
    exit(1)

example_root = Path(os.getcwd(), sys.argv[1])
if not example_root.is_dir():
    print(f"Example root ({example_root}) must be a directory")
    exit(2)

examples = read_examples_from_directory(example_root)
out = []
lint_falures = ""

for example in examples:
    if isinstance(example, Example):
        out.append(example.content_entry(example_root))
        continue

    for lint in example:
        print(lint)
        lint_falures += str(lint) + "\n"


contents_out = example_root / "contents.json"
lint_out = example_root / "lint.txt"

contents_out.write_text(json.dumps(out))
lint_out.write_text(lint_falures)

if lint_falures != "":
    exit(3)
