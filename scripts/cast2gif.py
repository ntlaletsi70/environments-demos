#!/usr/bin/env python3
"""Convert asciinema .cast file to animated GIF."""
import json
import subprocess
import sys
import os
import tempfile
from PIL import Image, ImageDraw, ImageFont


CAST_FILE = sys.argv[1] if len(sys.argv) > 1 else "demo.cast"
OUTPUT_GIF = sys.argv[2] if len(sys.argv) > 2 else "demo.gif"
COLS = 120
ROWS = 40
FONT_SIZE = 14
LINE_HEIGHT = 18
CHAR_WIDTH = 9
DURATION = 100  # ms per frame


def parse_cast(cast_path):
    """Parse asciinema cast file into frames."""
    with open(cast_path) as f:
        header = json.loads(f.readline())
        frames = []
        current_frame = []
        for line in f:
            if not line.strip():
                continue
            time, type_, data = json.loads(line)
            if type_ == "o":  # output
                current_frame.append((time, data))
            elif type_ == "r":  # resize
                pass
        return header, current_frame


def render_frame(lines, font):
    """Render text lines to PIL image."""
    width = COLS * CHAR_WIDTH
    height = ROWS * LINE_HEIGHT
    img = Image.new("RGB", (width, height), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    for i, line in enumerate(lines):
        if i >= ROWS:
            break
        draw.text((0, i * LINE_HEIGHT), line[:COLS], font=font, fill=(0, 255, 0))

    return img


def main():
    if not os.path.exists(CAST_FILE):
        print(f"Cast file not found: {CAST_FILE}")
        sys.exit(1)

    header, output_data = parse_cast(CAST_FILE)

    # Try to load a monospace font
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", FONT_SIZE)
    except:
        font = ImageFont.load_default()

    frames = []
    current_lines = [""] * ROWS

    for time_delta, data in output_data:
        # Process ANSI escape sequences (simplified)
        lines = data.split("\n")
        for line in lines:
            if line:
                current_lines.append(line)
                if len(current_lines) > ROWS:
                    current_lines = current_lines[-ROWS:]

        # Render every few outputs to limit frame count
        if len(frames) < 200:  # max frames
            frames.append(render_frame(current_lines, font))

    if not frames:
        print("No frames to render")
        sys.exit(1)

    frames[0].save(
        OUTPUT_GIF,
        save_all=True,
        append_images=frames[1:],
        duration=DURATION,
        loop=0,
        optimize=True,
    )
    print(f"Created {OUTPUT_GIF} with {len(frames)} frames")


if __name__ == "__main__":
    main()