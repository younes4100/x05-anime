#!/usr/bin/env python3
"""Trim fully transparent margins from the transparent brand PNGs.

The Flutter UI draws ``logo_mark.png`` and ``wordmark.png`` with
``BoxFit.contain`` inside fixed boxes, so transparent padding is wasted space:
it makes the artwork look smaller than the slot it lives in.

Usage:
    python tool/trim_transparent.py --padding 12 image.png [...]
    python tool/trim_transparent.py --square --padding 24 image.png

``--square`` keeps a square canvas (centring the artwork), which matters for
the mark because launchers and the home screen place it in square slots.
"""

from __future__ import annotations

import argparse

from PIL import Image


def trim(path: str, padding: int, square: bool) -> None:
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    box = alpha.getbbox()
    if box is None:
        print(f"skip (empty alpha): {path}")
        return

    # Crop to the ink first, then rebuild the canvas with exactly [padding]
    # pixels around it. Clamping the crop bounds would silently keep whatever
    # transparent margin the renderer already produced (often less than the
    # padding we want), and would make a second run a no-op.
    cropped = image.crop(box)

    if square:
        side = max(cropped.width, cropped.height) + padding * 2
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        canvas.paste(
            cropped,
            (
                (side - cropped.width) // 2,
                (side - cropped.height) // 2,
            ),
        )
        cropped = canvas
    elif padding > 0:
        canvas = Image.new(
            "RGBA",
            (cropped.width + padding * 2, cropped.height + padding * 2),
            (0, 0, 0, 0),
        )
        canvas.paste(cropped, (padding, padding))
        cropped = canvas

    cropped.save(path, optimize=True)
    print(
        f"trimmed {path}: {image.width}x{image.height} -> "
        f"{cropped.width}x{cropped.height}"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("images", nargs="+", help="PNG files to trim in place")
    parser.add_argument(
        "--padding",
        type=int,
        default=0,
        help="transparent padding to keep around the artwork, in pixels",
    )
    parser.add_argument(
        "--square",
        action="store_true",
        help="pad the result to a square canvas",
    )
    args = parser.parse_args()
    for image in args.images:
        trim(image, max(0, args.padding), args.square)


if __name__ == "__main__":
    main()
