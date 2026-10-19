"""Convert PNG files in a directory tree to lossless WebP format, with optional removal of the original PNGs.
Options:
  --remove-png   Move source PNG files to the Recycle Bin after successful conversion.
  --silent       Suppress progress output and only print errors.
  --help         Show this help message and exit.
"""

from __future__ import annotations

import argparse
import ctypes
import sys
from ctypes import wintypes
from pathlib import Path

from PIL import Image


FO_DELETE = 0x0003
FOF_SILENT = 0x0004
FOF_NOCONFIRMATION = 0x0010
FOF_ALLOWUNDO = 0x0040
FOF_NOERRORUI = 0x0400


class SHFILEOPSTRUCTW(ctypes.Structure):
	"""Describe the Windows shell operation used to move files to the Recycle Bin."""

	_fields_ = [
		("hwnd", wintypes.HWND),
		("wFunc", wintypes.UINT),
		("pFrom", wintypes.LPCWSTR),
		("pTo", wintypes.LPCWSTR),
		("fFlags", wintypes.WORD),
		("fAnyOperationsAborted", wintypes.BOOL),
		("hNameMappings", wintypes.LPVOID),
		("lpszProgressTitle", wintypes.LPCWSTR),
	]


def parse_args() -> argparse.Namespace:
	"""Parse command line arguments for the input directory and optional flags."""

	parser = argparse.ArgumentParser(
		description="Convert PNG files in a directory tree to lossless WebP."
	)
	parser.add_argument(
		"directory",
		nargs="?",
		default=".",
		help="Input directory. Relative and absolute paths are supported.",
	)
	parser.add_argument(
		"--remove-png",
		action="store_true",
		help="Move source PNG files to the Recycle Bin after successful conversion.",
	)
	parser.add_argument(
		"--silent",
		action="store_true",
		help="Suppress progress output and only print errors.",
	)
	return parser.parse_args()


def log(message: str, *, silent: bool, error: bool = False) -> None:
	"""Print progress messages unless silent mode is enabled, while always showing errors."""

	if silent and not error:
		return

	stream = sys.stderr if error else sys.stdout
	print(message, file=stream)


def iter_png_files(directory: Path) -> list[Path]:
	"""Collect all PNG files from the target directory and its subdirectories."""

	return sorted(
		path for path in directory.rglob("*") if path.is_file() and path.suffix.lower() == ".png"
	)


def normalize_image_for_webp(image: Image.Image) -> Image.Image:
	"""Convert image data to a WebP-compatible mode while preserving alpha when present."""

	if image.mode in {"RGB", "RGBA"}:
		return image
	if "A" in image.getbands():
		return image.convert("RGBA")
	return image.convert("RGB")


def convert_png_to_webp(png_path: Path, silent: bool) -> Path:
	"""Convert one PNG file to a lossless WebP file next to the original."""

	webp_path = png_path.with_suffix(".webp")
	log(f"[CONVERT] {png_path} -> {webp_path}", silent=silent)

	with Image.open(png_path) as image:
		converted = normalize_image_for_webp(image)
		converted.save(
			webp_path,
			format="WEBP",
			lossless=True,
			quality=100,
			method=0,
			exact=True,
		)

	return webp_path


def move_to_recycle_bin(path: Path) -> None:
	"""Move a file to the Windows Recycle Bin without prompting the user."""

	shell_operation = SHFILEOPSTRUCTW()
	shell_operation.wFunc = FO_DELETE
	shell_operation.pFrom = f"{path.resolve()}\0\0"
	shell_operation.fFlags = (
		FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_NOERRORUI | FOF_SILENT
	)

	result = ctypes.windll.shell32.SHFileOperationW(ctypes.byref(shell_operation))
	if result != 0:
		raise OSError(f"Failed to move '{path}' to the Recycle Bin (code: {result}).")


def main() -> int:
	"""Run the directory conversion flow and report a non-zero code on failure."""

	args = parse_args()
	target_directory = Path(args.directory).expanduser().resolve()

	if not target_directory.exists():
		log(f"[ERROR] Directory does not exist: {target_directory}", silent=args.silent, error=True)
		return 1
	if not target_directory.is_dir():
		log(f"[ERROR] Path is not a directory: {target_directory}", silent=args.silent, error=True)
		return 1

	png_files = iter_png_files(target_directory)
	if not png_files:
		log(f"[INFO] No PNG files found in: {target_directory}", silent=args.silent)
		return 0

	log(f"[START] Found {len(png_files)} PNG file(s) in {target_directory}", silent=args.silent)

	success_count = 0
	failure_count = 0

	for png_path in png_files:
		try:
			convert_png_to_webp(png_path, args.silent)
			if args.remove_png:
				move_to_recycle_bin(png_path)
				log(f"[REMOVE] Moved to Recycle Bin: {png_path}", silent=args.silent)
			success_count += 1
		except Exception as exc:
			failure_count += 1
			log(f"[ERROR] {png_path}: {exc}", silent=args.silent, error=True)

	log(
		f"[DONE] Converted: {success_count}, Failed: {failure_count}, Remove PNG: {args.remove_png}",
		silent=args.silent,
	)
	return 0 if failure_count == 0 else 1


if __name__ == "__main__":
	raise SystemExit(main())
