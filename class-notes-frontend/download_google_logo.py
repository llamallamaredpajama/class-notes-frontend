#!/usr/bin/env python3
"""
Download and prepare Google logo for the sign-in button
"""

import os
import urllib.request
from PIL import Image

def download_google_logo():
    # Create Assets directory if it doesn't exist
    assets_dir = "Assets.xcassets"
    google_logo_dir = os.path.join(assets_dir, "google-logo.imageset")
    os.makedirs(google_logo_dir, exist_ok=True)
    
    # Google's G logo URL (official branding)
    logo_url = "https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg"
    
    # For now, let's create a simple G logo representation
    # In production, you should use Google's official branding assets
    
    # Create a simple G logo using PIL
    sizes = [(24, "1x"), (48, "2x"), (72, "3x")]
    
    for size, scale in sizes:
        # Create a white background
        img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        
        # Save as PNG
        filename = f"google-logo@{scale}.png" if scale != "1x" else "google-logo.png"
        filepath = os.path.join(google_logo_dir, filename)
        img.save(filepath, "PNG")
        print(f"Created placeholder: {filename}")
    
    # Create Contents.json
    contents = {
        "images": [
            {
                "filename": "google-logo.png",
                "idiom": "universal",
                "scale": "1x"
            },
            {
                "filename": "google-logo@2x.png",
                "idiom": "universal",
                "scale": "2x"
            },
            {
                "filename": "google-logo@3x.png",
                "idiom": "universal",
                "scale": "3x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    import json
    contents_path = os.path.join(google_logo_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"\nGoogle logo placeholder created in: {google_logo_dir}")
    print("\nIMPORTANT: Replace these placeholder images with the official Google 'G' logo")
    print("Download from: https://developers.google.com/identity/branding-guidelines")
    print("Use the colored 'G' logo on white background")

if __name__ == "__main__":
    download_google_logo() 