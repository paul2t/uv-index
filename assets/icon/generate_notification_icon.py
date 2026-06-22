"""One-off script to generate the monochrome status-bar notification icon.

Android renders notification icons as a white silhouette from the alpha
channel, so this must be flat white on a transparent background (unlike the
colorful app icon).
"""
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "C:/Windows/Fonts/segoeuib.ttf"

# (density, px size, output dir) — standard Android notification icon sizes.
DENSITIES = [
    ("mdpi", 24),
    ("hdpi", 36),
    ("xhdpi", 48),
    ("xxhdpi", 72),
    ("xxxhdpi", 96),
]

OUT_BASE = "../../android/app/src/main/res"


def render(size):
    # Render at 4x then downscale for clean anti-aliasing.
    scale = 4
    canvas = Image.new("RGBA", (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(FONT_PATH, int(size * scale * 0.62))
    text = "UV"
    box = draw.textbbox((0, 0), text, font=font)
    w, h = box[2] - box[0], box[3] - box[1]
    x = (canvas.width - w) // 2 - box[0]
    y = (canvas.height - h) // 2 - box[1]
    draw.text((x, y), text, font=font, fill=(255, 255, 255, 255))
    return canvas.resize((size, size), Image.LANCZOS)


for density, size in DENSITIES:
    img = render(size)
    out_dir = f"{OUT_BASE}/drawable-{density}"
    img.save(f"{out_dir}/ic_notification.png")
    print(f"Saved {out_dir}/ic_notification.png ({size}x{size})")
