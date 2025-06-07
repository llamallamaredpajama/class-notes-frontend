#!/usr/bin/env python3
"""
App Icon Generator for iOS/macOS
Generates all required icon sizes from a source image
"""

import os
import sys
from PIL import Image
import json

def generate_icons(source_image_path, output_dir):
    """Generate all required icon sizes from source image"""
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Open source image
    try:
        source_img = Image.open(source_image_path)
        # Convert to RGBA if not already
        if source_img.mode != 'RGBA':
            source_img = source_img.convert('RGBA')
    except Exception as e:
        print(f"Error opening image: {e}")
        sys.exit(1)
    
    # Define required sizes
    icon_sizes = [
        # iOS sizes (1024x1024 for all variants)
        ("AppIcon-iOS.png", 1024),
        ("AppIcon-iOS-Dark.png", 1024),
        ("AppIcon-iOS-Tinted.png", 1024),
        
        # macOS sizes
        ("AppIcon-16.png", 16),
        ("AppIcon-16@2x.png", 32),
        ("AppIcon-32.png", 32),
        ("AppIcon-32@2x.png", 64),
        ("AppIcon-128.png", 128),
        ("AppIcon-128@2x.png", 256),
        ("AppIcon-256.png", 256),
        ("AppIcon-256@2x.png", 512),
        ("AppIcon-512.png", 512),
        ("AppIcon-512@2x.png", 1024),
    ]
    
    # Generate each size
    for filename, size in icon_sizes:
        output_path = os.path.join(output_dir, filename)
        resized_img = source_img.resize((size, size), Image.Resampling.LANCZOS)
        resized_img.save(output_path, "PNG")
        print(f"Generated: {filename} ({size}x{size})")
    
    # Update Contents.json
    contents_json_path = os.path.join(output_dir, "Contents.json")
    contents = {
        "images": [
            {
                "filename": "AppIcon-iOS.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "dark"
                    }
                ],
                "filename": "AppIcon-iOS-Dark.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {
                        "appearance": "luminosity",
                        "value": "tinted"
                    }
                ],
                "filename": "AppIcon-iOS-Tinted.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "filename": "AppIcon-16.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "16x16"
            },
            {
                "filename": "AppIcon-16@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "16x16"
            },
            {
                "filename": "AppIcon-32.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "32x32"
            },
            {
                "filename": "AppIcon-32@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "32x32"
            },
            {
                "filename": "AppIcon-128.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "128x128"
            },
            {
                "filename": "AppIcon-128@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "128x128"
            },
            {
                "filename": "AppIcon-256.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "256x256"
            },
            {
                "filename": "AppIcon-256@2x.png",
                "idiom": "mac",
                "scale": "2x",
                "size": "256x256"
            },
            {
                "filename": "AppIcon-512.png",
                "idiom": "mac",
                "scale": "1x",
                "size": "512x512"
            },
            {
                "filename": "AppIcon-512@2x.png",
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
    
    with open(contents_json_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"\nUpdated Contents.json")
    print(f"\nAll icons generated successfully in: {output_dir}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 generate_app_icons.py <source_image_path>")
        print("Example: python3 generate_app_icons.py my_icon.png")
        sys.exit(1)
    
    source_image = sys.argv[1]
    output_dir = "Assets.xcassets/AppIcon.appiconset"
    
    if not os.path.exists(source_image):
        print(f"Error: Source image '{source_image}' not found")
        sys.exit(1)
    
    generate_icons(source_image, output_dir)

if __name__ == "__main__":
    main() 