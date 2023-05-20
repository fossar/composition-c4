#!/usr/bin/env python3
from pathlib import Path
from typing import cast, NotRequired, TypedDict
import argparse
import json
import shutil
import subprocess

Source = TypedDict(
    "Source",
    {
        "type": str,
        "url": str,
        "reference": str,
    },
)


class Package(TypedDict):
    name: str
    version: str
    source: NotRequired[Source]
    dist: Source


def clone_git_repo(url: str, rev: str, clone_target_path: Path) -> None:
    subprocess.check_call(
        ["git", "init"],
        cwd=clone_target_path,
    )
    subprocess.check_call(
        ["git", "fetch", url, rev, "--depth", "1"],
        cwd=clone_target_path,
    )
    subprocess.check_call(
        ["git", "reset", "--hard", "FETCH_HEAD"],
        cwd=clone_target_path,
    )


def fetch_composer_package(package: Package, clone_target_path: Path) -> None:
    assert (
        "source" in package and package["source"]["type"] == "git"
    ), f"Package “{package['name']}” does not have source of type “git”."

    clone_git_repo(
        url=package["source"]["url"],
        rev=package["source"]["reference"],
        clone_target_path=clone_target_path,
    )

    # Clean up git directory to ensure reproducible output
    shutil.rmtree(clone_target_path / ".git")


def make_package(
    package: Package,
    clone_target_path: Path,
) -> tuple[str, dict[str, Package]]:
    assert (
        package["source"]["reference"] == package["dist"]["reference"]
    ), f"Package “{package['name']}” has a mismatch between “reference” keys of “dist” and “source” keys."

    # While Composer repositories only really require `name`, `version` and `source`/`dist` fields,
    # we will use the original contents of the package’s entry from `composer.lock`, modifying just the sources.
    # Package entries in Composer repositories correspond to `composer.json` files [1]
    # and Composer appears to use them when regenerating the lockfile.
    # If we just used the minimal info, stuff like `autoloading` or `bin` programs would be broken.
    #
    # We cannot use `source` since Composer does not support path sources:
    #     "PathDownloader" is a dist type downloader and can not be used to download source
    #
    # [1]: https://getcomposer.org/doc/05-repositories.md#packages>

    # Copy the Package so that we do not mutate the original.
    package = cast(Package, dict(package))
    package.pop("source", None)
    package["dist"] = {
        "type": "path",
        "url": str(clone_target_path / package["name"] / package["version"]),
        "reference": package["dist"]["reference"],
    }

    return (
        package["name"],
        {
            package["version"]: package,
        },
    )


def main(
    lockfile_path: Path,
    output_path: Path,
) -> None:
    # We are generating a repository of type Composer
    # https://getcomposer.org/doc/05-repositories.md#composer
    with open(lockfile_path) as lockfile:
        lock = json.load(lockfile)
    repo_path = output_path / "repo"

    # We always need to fetch dev dependencies so that `composer update --lock` can update the config.
    packages_to_install = lock["packages"] + lock["packages-dev"]

    for package in packages_to_install:
        clone_target_path = repo_path / package["name"] / package["version"]
        clone_target_path.mkdir(parents=True)
        fetch_composer_package(package, clone_target_path)

    repo_manifest = {
        "packages": {
            package_name: metadata
            for package_name, metadata in [
                make_package(package, repo_path) for package in packages_to_install
            ]
        }
    }
    with open(output_path / "packages.json", "w") as repo_manifest_file:
        json.dump(
            repo_manifest,
            repo_manifest_file,
            indent=4,
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate composer repository for offline fetching"
    )
    parser.add_argument(
        "lockfile_path",
        help="Path to a composer lockfile",
    )
    parser.add_argument(
        "output_path",
        help="Output path to store the repository in",
    )

    args = parser.parse_args()

    main(
        lockfile_path=Path(args.lockfile_path),
        output_path=Path(args.output_path),
    )
