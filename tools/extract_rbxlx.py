#!/usr/bin/env python3
"""Extract Script / LocalScript / ModuleScript sources from .rbxlx into a Rojo-style tree."""

from __future__ import annotations

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path

SERVICES = {
	"ReplicatedStorage",
	"ServerScriptService",
	"StarterPlayer",
	"ServerStorage",
	"ReplicatedFirst",
	"StarterGui",
	"StarterPack",
	"Workspace",
	"Lighting",
	"Chat",
	"Teams",
	"SoundService",
}


def prop(props: ET.Element | None, name: str) -> str | None:
	if props is None:
		return None
	for child in props:
		if child.get("name") == name:
			return child.text if child.text is not None else ""
	return None


def extract(rbxlx: Path, out_root: Path) -> list[dict]:
	tree = ET.parse(rbxlx)
	root = tree.getroot()
	manifest: list[dict] = []

	def walk(el: ET.Element, path_parts: list[str], under: str | None) -> None:
		cls = el.get("class")
		props = el.find("Properties")
		name = prop(props, "Name") or cls or "Unnamed"
		new_under = under
		new_parts = path_parts
		if cls in SERVICES and not under:
			new_under = cls
			new_parts = [cls]
		elif under:
			new_parts = path_parts + [name]

		if cls in ("Script", "LocalScript", "ModuleScript") and under:
			source = prop(props, "Source") or ""
			filename = new_parts[-1]
			dir_parts = new_parts[:-1]
			if cls == "Script":
				fname = f"{filename}.server.lua"
			elif cls == "LocalScript":
				fname = f"{filename}.client.lua"
			else:
				fname = f"{filename}.lua"
			out_dir = out_root.joinpath(*dir_parts)
			out_dir.mkdir(parents=True, exist_ok=True)
			out_file = out_dir / fname
			out_file.write_text(source, encoding="utf-8")
			manifest.append(
				{
					"class": cls,
					"robloxPath": "/".join(new_parts),
					"file": str(out_file.relative_to(out_root)),
					"bytes": len(source.encode("utf-8")),
				}
			)

		for child in el:
			if child.tag == "Item":
				walk(child, new_parts, new_under)

	walk(root, [], None)
	return manifest


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("rbxlx", type=Path)
	parser.add_argument("out", type=Path)
	parser.add_argument("--manifest", type=Path)
	args = parser.parse_args()
	manifest = extract(args.rbxlx, args.out)
	print(f"Extracted {len(manifest)} scripts -> {args.out}")
	if args.manifest:
		args.manifest.write_text(json.dumps(manifest, indent=2), encoding="utf-8")


if __name__ == "__main__":
	main()
