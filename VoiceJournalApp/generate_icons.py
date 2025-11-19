#!/usr/bin/env python3
"""
Generate app icons for VoiceJournal
Design: Abstract sound wave combined with a journal/book motif
Simple, tint-friendly design that works at all sizes
"""

import os
import math

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Installing Pillow...")
    import subprocess
    subprocess.check_call(['pip', 'install', 'Pillow'])
    from PIL import Image, ImageDraw

def create_icon(size, output_path):
    """
    Create a VoiceJournal app icon at the specified size.

    Design concept: Abstract sound waves emanating from a stylized book/journal page.
    - Clean, geometric shapes
    - Works with Apple's tinting system
    - Clear and legible at small sizes
    """
    # Create image with white background (Apple will apply masking)
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)

    # Define colors - using a deep teal/blue that works well with tints
    primary_color = (0, 122, 140, 255)  # Teal - represents voice/sound

    # Calculate proportions based on size
    padding = size * 0.12
    center_x = size / 2
    center_y = size / 2

    # Draw stylized journal page (rounded rectangle in background)
    page_margin = size * 0.15
    page_left = page_margin
    page_top = page_margin
    page_right = size - page_margin
    page_bottom = size - page_margin
    corner_radius = size * 0.12

    # Draw the page background with subtle fill
    page_color = (240, 248, 250, 255)  # Very light teal tint
    draw.rounded_rectangle(
        [page_left, page_top, page_right, page_bottom],
        radius=corner_radius,
        fill=page_color,
        outline=primary_color,
        width=max(1, int(size * 0.02))
    )

    # Draw abstract sound waves (three curved lines)
    wave_center_x = center_x
    wave_center_y = center_y

    # Sound wave parameters
    wave_widths = [0.15, 0.25, 0.35]  # Proportions of size
    line_width = max(2, int(size * 0.035))

    for i, wave_width in enumerate(wave_widths):
        radius = size * wave_width

        # Draw arc (sound wave emanating to the right)
        arc_bbox = [
            wave_center_x - radius,
            wave_center_y - radius,
            wave_center_x + radius,
            wave_center_y + radius
        ]

        # Draw arcs on both sides for symmetry
        draw.arc(arc_bbox, start=-60, end=60, fill=primary_color, width=line_width)
        draw.arc(arc_bbox, start=120, end=240, fill=primary_color, width=line_width)

    # Draw central circle (represents the voice source/microphone)
    center_radius = size * 0.08
    center_bbox = [
        wave_center_x - center_radius,
        wave_center_y - center_radius,
        wave_center_x + center_radius,
        wave_center_y + center_radius
    ]
    draw.ellipse(center_bbox, fill=primary_color)

    # Add subtle journal lines (representing text/entries)
    line_y_positions = [0.70, 0.78, 0.86]
    line_start_x = size * 0.25
    line_end_x = size * 0.75
    line_color = (0, 122, 140, 100)  # Semi-transparent

    for y_pos in line_y_positions:
        y = size * y_pos
        draw.line(
            [(line_start_x, y), (line_end_x, y)],
            fill=line_color,
            width=max(1, int(size * 0.015))
        )

    # Save the image
    img.save(output_path, 'PNG')
    print(f"Created: {output_path} ({size}x{size})")

def main():
    # Output directory
    output_dir = "VoiceJournalApp/Shared/Assets.xcassets/AppIcon.appiconset"

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)

    # Define all required icon sizes
    # Format: (size, scale, platform, filename)
    icon_specs = [
        # iOS/iPadOS - Universal 1024x1024
        (1024, 1, "ios", "AppIcon-iOS-1024.png"),

        # macOS icons
        (16, 1, "mac", "AppIcon-macOS-16.png"),
        (32, 2, "mac", "AppIcon-macOS-16@2x.png"),
        (32, 1, "mac", "AppIcon-macOS-32.png"),
        (64, 2, "mac", "AppIcon-macOS-32@2x.png"),
        (128, 1, "mac", "AppIcon-macOS-128.png"),
        (256, 2, "mac", "AppIcon-macOS-128@2x.png"),
        (256, 1, "mac", "AppIcon-macOS-256.png"),
        (512, 2, "mac", "AppIcon-macOS-256@2x.png"),
        (512, 1, "mac", "AppIcon-macOS-512.png"),
        (1024, 2, "mac", "AppIcon-macOS-512@2x.png"),
    ]

    print("Generating VoiceJournal app icons...")
    print("=" * 50)

    for pixel_size, scale, platform, filename in icon_specs:
        output_path = os.path.join(output_dir, filename)
        create_icon(pixel_size, output_path)

    print("=" * 50)
    print("Icon generation complete!")
    print(f"\nGenerated {len(icon_specs)} icon files in {output_dir}")

    # Generate Contents.json
    generate_contents_json(output_dir)

def generate_contents_json(output_dir):
    """Generate the Contents.json file for the app icon set."""

    contents = {
        "images": [
            {
                "filename": "AppIcon-iOS-1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "filename": "AppIcon-macOS-16.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "16x16"
            },
            {
                "filename": "AppIcon-macOS-16@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "16x16"
            },
            {
                "filename": "AppIcon-macOS-32.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "32x32"
            },
            {
                "filename": "AppIcon-macOS-32@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "32x32"
            },
            {
                "filename": "AppIcon-macOS-128.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "128x128"
            },
            {
                "filename": "AppIcon-macOS-128@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "128x128"
            },
            {
                "filename": "AppIcon-macOS-256.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "256x256"
            },
            {
                "filename": "AppIcon-macOS-256@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "256x256"
            },
            {
                "filename": "AppIcon-macOS-512.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "512x512"
            },
            {
                "filename": "AppIcon-macOS-512@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "512x512"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    import json
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"\nUpdated: {contents_path}")

if __name__ == "__main__":
    main()
