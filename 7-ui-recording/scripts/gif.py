#!/usr/bin/env python3
"""Assemble PNG frames into an animated GIF."""
import os
import sys
from PIL import Image


FRAMES_DIR = "frames"
OUTPUT_GIF = "demo.gif"
DURATION = 500  # ms per frame


def main():
    frames = sorted(f for f in os.listdir(FRAMES_DIR) if f.endswith(".png"))
    if not frames:
        print("No frames found in", FRAMES_DIR)
        sys.exit(1)

    images = []
    for f in frames:
        path = os.path.join(FRAMES_DIR, f)
        img = Image.open(path)
        images.append(img)

    # Save as GIF
    images[0].save(
        OUTPUT_GIF,
        save_all=True,
        append_images=images[1:],
        duration=DURATION,
        loop=0,
        optimize=True,
    )
    print(f"Created {OUTPUT_GIF} with {len(images)} frames ({DURATION}ms each)")


if __name__ == "__main__":
    main()