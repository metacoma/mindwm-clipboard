from PIL import Image, ImageDraw, ImageFont, ImageColor
import os
import tempfile
import base64
import logging

SIZE = 64
STROKE = 4
PADDING = 4

logger = logging.getLogger(__name__)


def _load_font(size: int):
    font_candidates = [
        "arial.ttf",
        "DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]

    for path in font_candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue

    return ImageFont.load_default()


def _parse_color(value: str):
    try:
        return ImageColor.getcolor(value, "RGBA")
    except ValueError:
        raise ValueError(f"Invalid color: {value}")


def image_to_kando_image(path: str) -> str:
    if not os.path.isfile(path):
        raise FileNotFoundError(f"File not found: {path}")

    with open(path, "rb") as f:
        encoded = base64.b64encode(f.read()).decode("utf-8")

    return f"data:image/png;base64,{encoded}"


def generate_circle_icon(
    text: str,
    output: str = "/tmp/icon.png",
    border_color: str = "black",
    text_color: str = "black",
    size: int = SIZE,
):
    border_rgba = _parse_color(border_color)
    text_rgba = _parse_color(text_color)

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    stroke = STROKE
    padding = PADDING

    # Circle outline
    bbox = (stroke, stroke, size - stroke, size - stroke)
    draw.ellipse(bbox, outline=border_rgba, width=stroke)

    inner = (size - 2 * stroke) - 2 * padding

    best_font = _load_font(8)
    best_w = best_h = 0

    for fs in range(size, 5, -1):
        font = _load_font(fs)
        tb = draw.textbbox((0, 0), text, font=font)
        w, h = tb[2] - tb[0], tb[3] - tb[1]

        if w <= inner and h <= inner:
            best_font = font
            best_w, best_h = w, h
            break

    x = (size - best_w) / 2
    y = (size - best_h) / 2

    draw.text((x, y), text, font=best_font, fill=text_rgba)
    img.save(output)

    return output

def generate_kando_icon(
    text: str,
    border_color: str = "black",
    text_color: str = "black",
    size: int = 64,
    debug_dir: str | None = None,
) -> str:

    if debug_dir:
        os.makedirs(debug_dir, exist_ok=True)
        output_path = os.path.join(debug_dir, f"{text}.png")
    else:
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
        output_path = tmp.name
        tmp.close()

    generate_circle_icon(
        text=text,
        output=output_path,
        border_color=border_color,
        text_color=text_color,
        size=size,
    )

    result = image_to_kando_image(output_path)

    return result
