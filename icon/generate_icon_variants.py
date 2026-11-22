#!/usr/bin/env python3
"""Generate crisp, 4x-supersampled Flipping Seven Calculator app icon variants.

Produces opaque 1024x1024 Light, Dark, and Tinted PNG icons following Apple HIG
and APP264401-I originality constraints: pure minimalist two-card + sculpted '7'
silhouette designed for 29pt, 60pt, and 1024pt clarity.
"""

from __future__ import annotations

import math
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
SCALE = 4
WORK = SIZE * SCALE


def rgb(hex_value: str) -> tuple[int, int, int]:
    value = hex_value.removeprefix("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def lerp_color(
    c1: tuple[int, int, int], c2: tuple[int, int, int], t: float
) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return (
        int(round(c1[0] + (c2[0] - c1[0]) * t)),
        int(round(c1[1] + (c2[1] - c1[1]) * t)),
        int(round(c1[2] + (c2[2] - c1[2]) * t)),
    )


@dataclass(frozen=True)
class IconTheme:
    bg_center: tuple[int, int, int]
    bg_edge: tuple[int, int, int]
    back_card_top: tuple[int, int, int]
    back_card_bottom: tuple[int, int, int]
    back_border: tuple[int, int, int]
    back_border_alpha: int
    front_card_top: tuple[int, int, int]
    front_card_bottom: tuple[int, int, int]
    front_border: tuple[int, int, int]
    front_border_alpha: int
    seven_color: tuple[int, int, int]
    shadow_color: tuple[int, int, int]
    shadow_alpha_back: int
    shadow_alpha_front: int


LIGHT = IconTheme(
    bg_center=rgb("286BB8"),
    bg_edge=rgb("153B6E"),
    back_card_top=rgb("3B7EC9"),
    back_card_bottom=rgb("2761A6"),
    back_border=rgb("EAF2FC"),
    back_border_alpha=155,
    front_card_top=rgb("FFFCF7"),
    front_card_bottom=rgb("F5EFE4"),
    front_border=rgb("F0C14B"),
    front_border_alpha=240,
    seven_color=rgb("154175"),
    shadow_color=rgb("07172B"),
    shadow_alpha_back=72,
    shadow_alpha_front=86,
)

DARK = IconTheme(
    bg_center=rgb("102038"),
    bg_edge=rgb("050B14"),
    back_card_top=rgb("244775"),
    back_card_bottom=rgb("183254"),
    back_border=rgb("9CC4F0"),
    back_border_alpha=115,
    front_card_top=rgb("2D5282"),
    front_card_bottom=rgb("1F3B61"),
    front_border=rgb("F2C755"),
    front_border_alpha=235,
    seven_color=rgb("FFFBF2"),
    shadow_color=rgb("010408"),
    shadow_alpha_back=110,
    shadow_alpha_front=125,
)

TINTED = IconTheme(
    bg_center=rgb("141414"),
    bg_edge=rgb("000000"),
    back_card_top=rgb("6E6E6E"),
    back_card_bottom=rgb("545454"),
    back_border=rgb("E0E0E0"),
    back_border_alpha=150,
    front_card_top=rgb("F5F5F5"),
    front_card_bottom=rgb("DCDCDC"),
    front_border=rgb("FFFFFF"),
    front_border_alpha=245,
    seven_color=rgb("0B0B0B"),
    shadow_color=rgb("000000"),
    shadow_alpha_back=110,
    shadow_alpha_front=125,
)


def make_radial_background(
    size: int, center_rgb: tuple[int, int, int], edge_rgb: tuple[int, int, int]
) -> Image.Image:
    grid = 256
    bg = Image.new("RGB", (grid, grid))
    px = bg.load()
    cx = grid * 0.48
    cy = grid * 0.36
    max_r = math.hypot(grid * 0.72, grid * 0.78)
    for y in range(grid):
        for x in range(grid):
            d = math.hypot(x - cx, y - cy) / max_r
            t = min(1.0, d * d * 0.88 + d * 0.12)
            px[x, y] = lerp_color(center_rgb, edge_rgb, t)
    return bg.resize((size, size), resample=Image.Resampling.BICUBIC).convert("RGBA")


def make_vertical_gradient(
    width: int, height: int, top_rgb: tuple[int, int, int], bottom_rgb: tuple[int, int, int]
) -> Image.Image:
    strip = Image.new("RGB", (1, 256))
    px = strip.load()
    for y in range(256):
        px[0, y] = lerp_color(top_rgb, bottom_rgb, y / 255.0)
    return strip.resize((width, height), resample=Image.Resampling.BILINEAR).convert("RGBA")


def make_rounded_mask(size: tuple[int, int], box: tuple[int, int, int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(box, radius=radius, fill=255)
    return mask


def make_card(theme: IconTheme, *, front: bool) -> Image.Image:
    width = (516 if front else 468) * SCALE
    height = (696 if front else 636) * SCALE
    pad = 120 * SCALE
    radius = (78 if front else 72) * SCALE
    canvas_w = width + pad * 2
    canvas_h = height + pad * 2
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    # Crisp grounded shadow tuned to avoid smudging at 29pt/60pt
    shadow = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    base_alpha = theme.shadow_alpha_front if front else theme.shadow_alpha_back
    sdraw.rounded_rectangle(
        (pad + 8 * SCALE, pad + 18 * SCALE, pad + width + 8 * SCALE, pad + height + 18 * SCALE),
        radius=radius,
        fill=(*theme.shadow_color, base_alpha),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=22 * SCALE))
    canvas.alpha_composite(shadow)

    card_box = (pad, pad, pad + width, pad + height)
    grad = make_vertical_gradient(
        width,
        height,
        theme.front_card_top if front else theme.back_card_top,
        theme.front_card_bottom if front else theme.back_card_bottom,
    )
    fill_layer = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    fill_layer.paste(grad, (pad, pad))
    mask = make_rounded_mask((canvas_w, canvas_h), card_box, radius)
    fill_layer.putalpha(mask)
    canvas.alpha_composite(fill_layer)

    draw = ImageDraw.Draw(canvas)
    border_width = (15 if front else 10) * SCALE
    border_color = (
        (*theme.front_border, theme.front_border_alpha)
        if front
        else (*theme.back_border, theme.back_border_alpha)
    )
    draw.rounded_rectangle(card_box, radius=radius, outline=border_color, width=border_width)

    if front:
        number_font = ImageFont.truetype(str(FONT_PATH), size=535 * SCALE)
        cx = pad + width // 2 - 4 * SCALE
        cy = pad + height // 2 + 12 * SCALE
        draw.text(
            (cx, cy),
            "7",
            font=number_font,
            fill=(*theme.seven_color, 255),
            anchor="mm",
        )

    return canvas


def rotate_high_quality(image: Image.Image, degrees: float) -> Image.Image:
    return image.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=True)


def create_icon(theme: IconTheme) -> Image.Image:
    canvas = make_radial_background(WORK, theme.bg_center, theme.bg_edge)

    back_card = rotate_high_quality(make_card(theme, front=False), 12)
    bx = (WORK - back_card.width) // 2 - 140 * SCALE
    by = (WORK - back_card.height) // 2 + 14 * SCALE
    canvas.alpha_composite(back_card, dest=(bx, by))

    front_card = rotate_high_quality(make_card(theme, front=True), -6)
    fx = (WORK - front_card.width) // 2 + 74 * SCALE
    fy = (WORK - front_card.height) // 2 - 2 * SCALE
    canvas.alpha_composite(front_card, dest=(fx, fy))

    return canvas.convert("RGB").resize((SIZE, SIZE), resample=Image.Resampling.LANCZOS)


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
