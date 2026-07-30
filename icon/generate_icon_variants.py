#!/usr/bin/env python3
"""Generate the Flipping Seven Calculator app icon variants."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


SCRIPT_DIR = Path(__file__).resolve().parent
APP_DIR = SCRIPT_DIR.parent / "flip7calculator"
OUTPUT_DIR = APP_DIR / "Assets.xcassets" / "AppIcon.appiconset"
FONT_PATH = APP_DIR / "Nunito-Black.ttf"

LIGHT_OUT = OUTPUT_DIR / "AppIcon-1024.png"
DARK_OUT = OUTPUT_DIR / "AppIcon-1024-dark.png"
TINTED_OUT = OUTPUT_DIR / "AppIcon-1024-tinted.png"

SIZE = 1024


def rgb(hex_value: str) -> tuple[int, int, int]:
    value = hex_value.removeprefix("#")
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))


@dataclass(frozen=True)
class IconTheme:
    background: tuple[int, int, int]
    back_card: tuple[int, int, int]
    back_border: tuple[int, int, int]
    front_card: tuple[int, int, int]
    front_border: tuple[int, int, int]
    seven: tuple[int, int, int]
    seven_shadow: tuple[int, int, int]
    gold: tuple[int, int, int]
    copper: tuple[int, int, int]
    shadow: tuple[int, int, int]


LIGHT = IconTheme(
    background=rgb("184D8A"),
    back_card=rgb("205EA4"),
    back_border=rgb("FFF7EB"),
    front_card=rgb("FFF7EB"),
    front_border=rgb("F1C24B"),
    seven=rgb("205EA4"),
    seven_shadow=rgb("D99A20"),
    gold=rgb("F1C24B"),
    copper=rgb("E47B58"),
    shadow=rgb("0B243D"),
)

DARK = IconTheme(
    background=rgb("0A1728"),
    back_card=rgb("184D8A"),
    back_border=rgb("DCE6F0"),
    front_card=rgb("16263D"),
    front_border=rgb("E7C65D"),
    seven=rgb("F5F7FA"),
    seven_shadow=rgb("B47A18"),
    gold=rgb("E7C65D"),
    copper=rgb("EF8D6C"),
    shadow=rgb("010407"),
)

TINTED = IconTheme(
    background=rgb("000000"),
    back_card=rgb("727272"),
    back_border=rgb("FFFFFF"),
    front_card=rgb("C9C9C9"),
    front_border=rgb("FFFFFF"),
    seven=rgb("000000"),
    seven_shadow=rgb("FFFFFF"),
    gold=rgb("FFFFFF"),
    copper=rgb("8A8A8A"),
    shadow=rgb("000000"),
)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_PATH), size=size)


def make_card(theme: IconTheme, *, front: bool) -> Image.Image:
    width, height, padding = 468, 650, 86
    canvas = Image.new("RGBA", (width + padding * 2, height + padding * 2), (0, 0, 0, 0))

    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_draw.rounded_rectangle(
        (padding + 14, padding + 24, padding + width + 14, padding + height + 24),
        radius=70,
        fill=(*theme.shadow, 150 if front else 96),
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=28))
    canvas.alpha_composite(shadow_layer)

    draw = ImageDraw.Draw(canvas)
    card_box = (padding, padding, padding + width, padding + height)
    fill = theme.front_card if front else theme.back_card
    border = theme.front_border if front else theme.back_border
    draw.rounded_rectangle(card_box, radius=70, fill=fill, outline=border, width=24)

    if front:
        draw_front_card(draw, theme, padding, width, height)
    else:
        draw_back_card(draw, theme, padding, width, height)

    return canvas


def draw_back_card(
    draw: ImageDraw.ImageDraw,
    theme: IconTheme,
    padding: int,
    width: int,
    height: int,
) -> None:
    inset = 44
    draw.rounded_rectangle(
        (
            padding + inset,
            padding + inset,
            padding + width - inset,
            padding + height - inset,
        ),
        radius=48,
        outline=(*theme.back_border, 220),
        width=10,
    )

    center_x = padding + width // 2
    center_y = padding + height // 2
    bars = (
        (theme.gold, 188, -48),
        (theme.back_border, 244, 0),
        (theme.copper, 150, 48),
    )
    for color, bar_width, offset_y in bars:
        draw.rounded_rectangle(
            (
                center_x - bar_width // 2,
                center_y + offset_y - 12,
                center_x + bar_width // 2,
                center_y + offset_y + 12,
            ),
            radius=12,
            fill=color,
        )


def draw_front_card(
    draw: ImageDraw.ImageDraw,
    theme: IconTheme,
    padding: int,
    width: int,
    height: int,
) -> None:
    number_font = font(430)
    center_x = padding + width // 2
    center_y = padding + height // 2 + 22

    draw.text(
        (center_x + 11, center_y + 13),
        "7",
        font=number_font,
        fill=theme.seven_shadow,
        anchor="mm",
        stroke_width=3,
        stroke_fill=theme.seven_shadow,
    )
    draw.text(
        (center_x, center_y),
        "7",
        font=number_font,
        fill=theme.seven,
        anchor="mm",
    )

    dot_radius = 18
    dot_x = padding + 60
    dot_y = padding + 60
    draw.ellipse(
        (dot_x - dot_radius, dot_y - dot_radius, dot_x + dot_radius, dot_y + dot_radius),
        fill=theme.copper,
    )

def rotate(image: Image.Image, degrees: float) -> Image.Image:
    return image.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=True)


def create_icon(theme: IconTheme) -> Image.Image:
    base = Image.new("RGBA", (SIZE, SIZE), (*theme.background, 255))

    back_card = rotate(make_card(theme, front=False), -14)
    base.alpha_composite(back_card, dest=(-24, 82))

    front_card = rotate(make_card(theme, front=True), 9)
    base.alpha_composite(front_card, dest=(284, 62))

    return base.convert("RGB")


def save_icon(image: Image.Image, destination: Path) -> None:
    image.save(destination, format="PNG", optimize=True)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    save_icon(create_icon(LIGHT), LIGHT_OUT)
    save_icon(create_icon(DARK), DARK_OUT)
    save_icon(create_icon(TINTED), TINTED_OUT)

    print(f"Wrote {LIGHT_OUT}")
    print(f"Wrote {DARK_OUT}")
    print(f"Wrote {TINTED_OUT}")


if __name__ == "__main__":
    main()
