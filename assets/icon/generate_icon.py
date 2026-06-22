"""One-off script to generate the app icon (run manually, not part of the build).

Produces icon.png (full icon with background, for legacy/Play Store) and
icon_foreground.png (transparent background, for the Android adaptive icon
foreground layer).
"""
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
BACKGROUND = (43, 25, 25, 255)       # deep warm maroon, "not too bright"
COLOR_UV = (201, 106, 57, 255)       # muted burnt orange
COLOR_I = (224, 168, 62, 255)        # muted golden yellow
FONT_PATH = "C:/Windows/Fonts/segoeuib.ttf"
FONT_SIZE = 400

font = ImageFont.truetype(FONT_PATH, FONT_SIZE)


def measure(draw, text):
    box = draw.textbbox((0, 0), text, font=font)
    return box[2] - box[0], box[3] - box[1], box[0], box[1]


def draw_wordmark(canvas):
    draw = ImageDraw.Draw(canvas)
    uv_w, uv_h, uv_x0, uv_y0 = measure(draw, "UV")
    i_w, i_h, i_x0, i_y0 = measure(draw, "I")
    gap = 6
    total_w = uv_w + gap + i_w
    total_h = max(uv_h, i_h)

    start_x = (SIZE - total_w) // 2
    start_y = (SIZE - total_h) // 2

    draw.text((start_x - uv_x0, start_y - uv_y0), "UV", font=font, fill=COLOR_UV)
    draw.text(
        (start_x + uv_w + gap - i_x0, start_y - i_y0), "I", font=font, fill=COLOR_I
    )


# Full icon: solid background + wordmark (legacy icon / Play Store listing).
full = Image.new("RGBA", (SIZE, SIZE), BACKGROUND)
draw_wordmark(full)
full.save("icon.png")

# Foreground-only: transparent background, same wordmark, for the Android
# adaptive icon (composited over adaptive_icon_background at runtime).
foreground = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_wordmark(foreground)
foreground.save("icon_foreground.png")

print("Generated icon.png and icon_foreground.png")
