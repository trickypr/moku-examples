import enum
import re
from pathlib import Path
from typing import Dict, Generator, List, Optional, Union


EXAMPLE_NAME_REGEX = r"^# (?P<name>[\w\-\_ :()]+)$"


def is_example(path: Path):
    for item in path.iterdir():
        if item.is_file() and item.suffix == ".vhd":
            return True

    return False


def read_examples_from_directory(
    path: Path,
) -> Generator[Union[List["Lint"], "Example"], None, None]:
    for item in path.iterdir():
        if item.is_file():
            continue

        if not is_example(item):
            yield from read_examples_from_directory(item)
            continue

        yield example_from_path(item)


class Lints(enum.Enum):
    ContainsDir = "Examples can only contain directories named 'images'"
    MissingReadme = "Example directories must contain a README.md file"
    ReadmeDescription = (
        "Your readme is missing a level 1 heading or it does not match [\\w-_ :()]"
    )


class Lint:
    def __init__(self, source: Path, lint: Lints):
        self.source = source
        self.lint = lint

    def str_notice(self):
        # TODO: Write this out
        # https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions#setting-a-notice-message
        pass

    def __str__(self):
        return f"[{self.lint.name}] {self.source}\n\t{self.lint.value}"


class Example:
    def __init__(self, source: Path, name: str, vhdl: List[Path]):
        self.source = source
        self.name = name
        self.vhdl = vhdl

    def content_entry(self, root: Path) -> Dict[str, str | List[str]]:
        return {
            "title": self.name,
            "path": str(self.source.relative_to(root)),
            "files": [*map(lambda file: str(file.relative_to(self.source)), self.vhdl)],
        }


def collect_readme_info(readme: Path) -> Union[Lint, str]:
    "Collects a human-readable name from the readme or returns a lint"

    name_matches = re.search(EXAMPLE_NAME_REGEX, readme.read_text(), re.MULTILINE)

    if not name_matches:
        return Lint(readme, Lints.ReadmeDescription)

    return name_matches.group("name")


def example_from_path(path: Path) -> Union[List[Lint], Example]:
    vhdl = []
    readme: Optional[Path] = None
    name: Optional[str] = None
    lints = []

    for file in path.iterdir():
        if file.is_dir():
            if file.name == "images":
                continue
            lints.append(Lint(file, Lints.ContainsDir))
            continue

        if file.suffix == ".vhd":
            vhdl.append(file)

        if file.name == "README.md":
            readme = file

    if not readme:
        lints.append(Lint(path, Lints.MissingReadme))
    else:
        result = collect_readme_info(readme)
        if isinstance(result, Lint):
            lints.append(result)
        else:
            name = result

    if len(lints) != 0:
        return lints

    return Example(path, name or "", vhdl)
