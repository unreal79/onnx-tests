"""Merge two images by weighted averaging and save the result as lossless WebP or PNG.
Options:
	image1 image2    Paths to the two source image files.
	--weight1 VALUE  Weight for the first image, defaults to 0.5.
	--weight2 VALUE  Weight for the second image, defaults to 0.5.
	--normalize      Normalize both weights so their sum becomes 1.
	--png            Save the result as PNG instead of WebP.
	--silent         Suppress progress output and only print errors.
	--help           Show this help message and exit.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


def parse_args() -> argparse.Namespace:
	"""Parse command line arguments for input files, weights, and output format."""

	parser = argparse.ArgumentParser(
		description="Merge two source image files by weighted averaging and save the result."
	)
	parser.add_argument(
		"image1",
		help="Path to the first source image file. Relative and absolute paths are supported.",
	)
	parser.add_argument(
		"image2",
		help="Path to the second source image file. Relative and absolute paths are supported.",
	)
	parser.add_argument(
		"--weight1",
		type=float,
		default=0.5,
		help="Weight of the first image in the merged result. Default: 0.5.",
	)
	parser.add_argument(
		"--weight2",
		type=float,
		default=0.5,
		help="Weight of the second image in the merged result. Default: 0.5.",
	)
	parser.add_argument(
		"--normalize",
		action="store_true",
		help="Normalize both weights so their sum becomes 1 before merging.",
	)
	parser.add_argument(
		"--png",
		action="store_true",
		help="Save the result as PNG instead of lossless WebP.",
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


def resolve_input_image(path_text: str) -> Path:
	"""Resolve the provided image path and ensure that it points to an existing file."""

	image_path = Path(path_text).expanduser().resolve()
	if not image_path.exists():
		raise FileNotFoundError(f"Image file does not exist: {image_path}")
	if not image_path.is_file():
		raise ValueError(f"Path is not a file: {image_path}")
	return image_path


def resolve_weights(weight1: float, weight2: float, normalize: bool) -> tuple[float, float]:
	"""Validate weights and optionally normalize them when the corresponding flag is enabled."""

	if weight1 < 0 or weight2 < 0:
		raise ValueError("Weights must be non-negative.")

	if not normalize:
		return weight1, weight2

	total_weight = weight1 + weight2
	if total_weight <= 0:
		raise ValueError("The sum of both weights must be greater than zero when --normalize is used.")

	return weight1 / total_weight, weight2 / total_weight


def determine_output_mode(first_image: Image.Image, second_image: Image.Image) -> str:
	"""Select a compatible output mode that preserves alpha when either image has it."""

	first_has_alpha = "A" in first_image.getbands()
	second_has_alpha = "A" in second_image.getbands()
	return "RGBA" if first_has_alpha or second_has_alpha else "RGB"


def load_compatible_images(image1_path: Path, image2_path: Path) -> tuple[Image.Image, Image.Image, str]:
	"""Load both images, ensure equal size, and convert them to a shared mode for merging."""

	with Image.open(image1_path) as first_image, Image.open(image2_path) as second_image:
		if first_image.size != second_image.size:
			raise ValueError(
				"Images must have the same dimensions: "
				f"{image1_path.name}={first_image.size}, {image2_path.name}={second_image.size}"
			)

		output_mode = determine_output_mode(first_image, second_image)
		return first_image.convert(output_mode), second_image.convert(output_mode), output_mode


def merge_images(
	first_image: Image.Image,
	second_image: Image.Image,
	weight1: float,
	weight2: float,
	output_mode: str,
) -> Image.Image:
	"""Create a new image where each pixel is the weighted average of the source pixels."""

	first_array = np.asarray(first_image, dtype=np.float32)
	second_array = np.asarray(second_image, dtype=np.float32)
	merged_array = np.clip(first_array * weight1 + second_array * weight2, 0, 255).astype(np.uint8)
	return Image.fromarray(merged_array, mode=output_mode)


def build_output_path(image1_path: Path, image2_path: Path, save_as_png: bool) -> Path:
	"""Build the output file path using both source file names and the requested extension."""

	extension = ".png" if save_as_png else ".webp"
	output_name = f"merge_{image1_path.stem}_{image2_path.stem}{extension}"
	return image1_path.parent / output_name


def save_result_image(image: Image.Image, output_path: Path, save_as_png: bool) -> None:
	"""Save the merged image using PNG or lossless WebP settings."""

	if save_as_png:
		image.save(output_path, format="PNG")
		return

	image.save(
		output_path,
		format="WEBP",
		lossless=True,
		quality=100,
		method=0,
		exact=True,
	)


def main() -> int:
	"""Run the merge workflow and return a non-zero exit code if any step fails."""

	args = parse_args()

	try:
		image1_path = resolve_input_image(args.image1)
		image2_path = resolve_input_image(args.image2)
		resolved_weight1, resolved_weight2 = resolve_weights(args.weight1, args.weight2, args.normalize)

		log(f"[LOAD] {image1_path}", silent=args.silent)
		log(f"[LOAD] {image2_path}", silent=args.silent)
		first_image, second_image, output_mode = load_compatible_images(image1_path, image2_path)

		log(
			"[MERGE] "
			f"weight1={resolved_weight1:.4f}, weight2={resolved_weight2:.4f}, "
			f"normalize={args.normalize}, mode={output_mode}",
			silent=args.silent,
		)
		merged_image = merge_images(
			first_image,
			second_image,
			resolved_weight1,
			resolved_weight2,
			output_mode,
		)

		output_path = build_output_path(image1_path, image2_path, args.png)
		log(f"[SAVE] {output_path}", silent=args.silent)
		save_result_image(merged_image, output_path, args.png)
		log("[DONE] Merge completed successfully.", silent=args.silent)
		return 0
	except Exception as exc:
		log(f"[ERROR] {exc}", silent=args.silent, error=True)
		return 1


if __name__ == "__main__":
	raise SystemExit(main())
