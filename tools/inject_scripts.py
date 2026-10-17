#!/usr/bin/env python3
"""Write .lua sources from a Rojo-style tree back into matching ModuleScript/Script Items in an .rbxlx."""

from __future__ import annotations

import argparse
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
}


def prop_el(props: ET.Element | None, name: str) -> ET.Element | None:
	if props is None:
		return None
	for child in props:
		if child.get("name") == name:
			return child
	return None


def prop_text(props: ET.Element | None, name: str) -> str | None:
	el = prop_el(props, name)
	if el is None:
		return None
	return el.text if el.text is not None else ""


def set_source(props: ET.Element, source: str) -> None:
	src = prop_el(props, "Source")
	if src is None:
		src = ET.SubElement(props, "ProtectedString", {"name": "Source"})
	# ElementTree escapes on serialize; keep raw text.
	src.text = source


def inject(rbxlx: Path, src_root: Path, out: Path) -> tuple[int, int]:
	tree = ET.parse(rbxlx)
	root = tree.getroot()
	updated = 0
	missing = 0

	def walk(el: ET.Element, path_parts: list[str], under: str | None) -> None:
		nonlocal updated, missing
		cls = el.get("class")
		props = el.find("Properties")
		name = prop_text(props, "Name") or cls or "Unnamed"
		new_under = under
		new_parts = path_parts
		if cls in SERVICES and not under:
			new_under = cls
			new_parts = [cls]
		elif under:
			new_parts = path_parts + [name]

		if cls in ("Script", "LocalScript", "ModuleScript") and under and props is not None:
			filename = new_parts[-1]
			dir_parts = new_parts[:-1]
			if cls == "Script":
				fname = f"{filename}.server.lua"
			elif cls == "LocalScript":
				fname = f"{filename}.client.lua"
			else:
				fname = f"{filename}.lua"
			file_path = src_root.joinpath(*dir_parts) / fname
			if file_path.is_file():
				set_source(props, file_path.read_text(encoding="utf-8"))
				updated += 1
			else:
				missing += 1
				print(f"  missing source for {('/'.join(new_parts))} -> {file_path}")

		for child in el:
			if child.tag == "Item":
				walk(child, new_parts, new_under)

	walk(root, [], None)
	# Keep XML readable-ish; Roblox accepts this.
	tree.write(out, encoding="utf-8", xml_declaration=True)
	return updated, missing


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("rbxlx", type=Path)
	parser.add_argument("src", type=Path)
	parser.add_argument("-o", "--out", type=Path, required=True)
	args = parser.parse_args()
	updated, missing = inject(args.rbxlx, args.src, args.out)
	print(f"Updated {updated} scripts, missing {missing} -> {args.out}")


if __name__ == "__main__":
	main()
