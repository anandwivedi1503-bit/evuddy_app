#!/usr/bin/env python3
"""Build a large EVUDDY wordmark on brand yellow for launcher icons."""

from pathlib import Path

from PIL import Image, ImageFilter, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/images/evuddy_letters.png"
YELLOW = (255, 204, 0, 255)

ANDROID = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

IOS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def trim(im: Image.Image) -> Image.Image:
    if im.mode != "RGBA":
        im = im.convert("RGBA")
    bbox = im.split()[-1].point(lambda p: 255 if p > 12 else 0).getbbox()
    return im.crop(bbox) if bbox else im


def compose(size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), YELLOW)
    mark = trim(Image.open(SRC))
    # Fill almost the full icon width so EVUDDY reads large on the home screen.
    max_w = int(size * 0.92)
    max_h = int(size * 0.46)
    ratio = min(max_w / mark.width, max_h / mark.height)
    w = max(1, int(mark.width * ratio))
    h = max(1, int(mark.height * ratio))
    mark = mark.resize((w, h), Image.Resampling.LANCZOS)
    # Soft white plate so green/pink letters stay crisp on yellow.
    plate = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(plate)
    pad_x = (size - w) // 2
    pad_y = (size - h) // 2
    inset = max(2, size // 28)
    draw.rounded_rectangle(
        [pad_x - inset, pad_y - inset, pad_x + w + inset, pad_y + h + inset],
        radius=max(4, size // 16),
        fill=(255, 255, 255, 235),
    )
    plate = plate.filter(ImageFilter.GaussianBlur(radius=max(0.4, size / 180)))
    canvas = Image.alpha_composite(canvas, plate)
    canvas.paste(mark, ((size - w) // 2, (size - h) // 2), mark)
    return canvas.convert("RGB")


def main() -> None:
    for folder, size in ANDROID.items():
        dest = ROOT / "android/app/src/main/res" / folder / "ic_launcher.png"
        dest.parent.mkdir(parents=True, exist_ok=True)
        compose(size).save(dest, "PNG", optimize=True)

    ios_dir = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_dir.mkdir(parents=True, exist_ok=True)
    for name, size in IOS.items():
        compose(size).save(ios_dir / name, "PNG", optimize=True)

    web = ROOT / "web/icons"
    if web.exists():
        compose(192).save(web / "Icon-192.png", "PNG", optimize=True)
        compose(512).save(web / "Icon-512.png", "PNG", optimize=True)
        compose(192).save(web / "Icon-maskable-192.png", "PNG", optimize=True)
        compose(512).save(web / "Icon-maskable-512.png", "PNG", optimize=True)

    print("launcher icons written")


if __name__ == "__main__":
    main()
