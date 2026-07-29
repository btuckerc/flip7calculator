#!/usr/bin/env python3
"""
Generate the approved light, dark, and tinted app icon variants for Flipping Seven Calculator.

Design direction:
- a single, readable ledger sheet as the hero object
- the retained "LL" tab from the owner-approved icon artwork
- a flipping card with a visible "7" cue
- a die badge to communicate tabletop play
- no trademarked words, logos, or game-specific visual mimicry
"""

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
    hex_value = hex_value.removeprefix("#")
    return tuple(int(hex_value[index:index + 2], 16) for index in (0, 2, 4))


@dataclass(frozen=True)
class IconTheme:
    bg_top: tuple[int, int, int]
    bg_bottom: tuple[int, int, int]
    glow_primary: tuple[int, int, int]
    glow_secondary: tuple[int, int, int]
    outline: tuple[int, int, int]
    paper_front: tuple[int, int, int]
    paper_back: tuple[int, int, int]
    tab_fill: tuple[int, int, int]
    tab_text: tuple[int, int, int]
    row_neutral: tuple[int, int, int]
    row_a: tuple[int, int, int]
    row_b: tuple[int, int, int]
    row_c: tuple[int, int, int]
    ribbon: tuple[int, int, int]
    card_face: tuple[int, int, int]
    card_outline: tuple[int, int, int]
    card_number: tuple[int, int, int]
    fold_fill: tuple[int, int, int]
    die_fill: tuple[int, int, int]
    die_pip: tuple[int, int, int]
    shadow: tuple[int, int, int]


LIGHT = IconTheme(
    bg_top=rgb("4A79C5"),
    bg_bottom=rgb("0F3158"),
    glow_primary=rgb("F1C24B"),
    glow_secondary=rgb("6BA8E5"),
    outline=rgb("213042"),
    paper_front=rgb("FFF7EB"),
    paper_back=rgb("D7E8DA"),
    tab_fill=rgb("205EA4"),
    tab_text=rgb("FFF7EB"),
    row_neutral=rgb("DDE7F0"),
    row_a=rgb("205EA4"),
    row_b=rgb("F1C24B"),
    row_c=rgb("E47B58"),
    ribbon=rgb("E47B58"),
    card_face=rgb("184D8A"),
    card_outline=rgb("FFF7EB"),
    card_number=rgb("F1C24B"),
    fold_fill=rgb("FFF7EB"),
    die_fill=rgb("F1C24B"),
    die_pip=rgb("213042"),
    shadow=rgb("142130"),
)

DARK = IconTheme(
    bg_top=rgb("14243D"),
    bg_bottom=rgb("06111C"),
    glow_primary=rgb("7E5D1B"),
    glow_secondary=rgb("2D5F96"),
    outline=rgb("F5F7FA"),
    paper_front=rgb("23303C"),
    paper_back=rgb("16222B"),
    tab_fill=rgb("4B8FD7"),
    tab_text=rgb("F5F7FA"),
    row_neutral=rgb("556170"),
    row_a=rgb("68A8E3"),
    row_b=rgb("E7C65D"),
    row_c=rgb("EF8D6C"),
    ribbon=rgb("C77359"),
    card_face=rgb("10243B"),
    card_outline=rgb("F5F7FA"),
    card_number=rgb("E7C65D"),
    fold_fill=rgb("F5F7FA"),
    die_fill=rgb("D5B04B"),
    die_pip=rgb("0B1821"),
    shadow=rgb("010407"),
)

TINTED = IconTheme(
    bg_top=rgb("000000"),
    bg_bottom=rgb("000000"),
    glow_primary=rgb("000000"),
    glow_secondary=rgb("000000"),
    outline=rgb("FFFFFF"),
    paper_front=rgb("C3CBD5"),
    paper_back=rgb("7E8896"),
    tab_fill=rgb("FFFFFF"),
    tab_text=rgb("000000"),
    row_neutral=rgb("8E98A5"),
    row_a=rgb("FFFFFF"),
    row_b=rgb("E3E7EC"),
    row_c=rgb("C3CBD5"),
    ribbon=rgb("AEB7C2"),
    card_face=rgb("7E8896"),
    card_outline=rgb("FFFFFF"),
    card_number=rgb("FFFFFF"),
    fold_fill=rgb("FFFFFF"),
    die_fill=rgb("FFFFFF"),
    die_pip=rgb("000000"),
    shadow=rgb("000000"),
)


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)

    for y in range(size):
        ratio = y / (size - 1)
        color = tuple(
            int(top[index] + (bottom[index] - top[index]) * ratio)
            for index in range(3)
        )
        draw.line([(0, y), (size, y)], fill=color)

    return image


def add_soft_glow(base: Image.Image, color: tuple[int, int, int], center: tuple[int, int], radius: int, alpha: int) -> None:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    cx, cy = center
    bbox = (cx - radius, cy - radius, cx + radius, cy + radius)
    draw.ellipse(bbox, fill=(*color, alpha))
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=80))
    base.alpha_composite(overlay)


def add_background_texture(base: Image.Image, theme: IconTheme) -> None:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    for index, y in enumerate((248, 432, 616)):
        opacity = 12 if index == 1 else 9
        draw.rounded_rectangle(
            (148, y, 876, y + 20),
            radius=11,
            outline=(*theme.paper_front, opacity),
            width=3,
        )

    base.alpha_composite(overlay.filter(ImageFilter.GaussianBlur(radius=10)))


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_PATH), size=size)


def scale_image(image: Image.Image, factor: float) -> Image.Image:
    return image.resize(
        (int(image.width * factor), int(image.height * factor)),
        Image.Resampling.LANCZOS,
    )


def draw_ll_tab(draw: ImageDraw.ImageDraw, theme: IconTheme, origin: tuple[int, int]) -> None:
    x, y = origin
    draw.rounded_rectangle((x, y, x + 214, y + 112), radius=28, fill=theme.tab_fill)

    tab_font = font(92)
    draw.text(
        (x + 107, y + 58),
        "LL",
        font=tab_font,
        fill=theme.tab_text,
        anchor="mm",
    )


def draw_row(draw: ImageDraw.ImageDraw, theme: IconTheme, top_left: tuple[int, int], accent: tuple[int, int, int], long_width: int) -> None:
    x, y = top_left
    draw.ellipse((x, y, x + 34, y + 34), fill=accent)
    draw.rounded_rectangle((x + 56, y + 4, x + 56 + long_width, y + 30), radius=13, fill=theme.row_neutral)
    draw.rounded_rectangle((x + 56 + long_width + 18, y + 4, x + 56 + long_width + 98, y + 30), radius=13, fill=accent)


def make_pencil(theme: IconTheme) -> Image.Image:
    canvas = Image.new("RGBA", (220, 290), (0, 0, 0, 0))

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((74, 56, 150, 268), radius=26, fill=(*theme.shadow, 88))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=16))
    canvas.alpha_composite(shadow)

    draw = ImageDraw.Draw(canvas)
    body = (96, 72, 132, 206)
    draw.rounded_rectangle(body, radius=18, fill=theme.row_a, outline=theme.outline, width=6)
    draw.rounded_rectangle((94, 206, 134, 232), radius=12, fill=theme.row_neutral, outline=theme.outline, width=4)
    draw.rounded_rectangle((90, 232, 138, 270), radius=14, fill=theme.ribbon, outline=theme.outline, width=4)
    draw.polygon([(96, 72), (132, 72), (114, 34)], fill=theme.row_b)
    draw.polygon([(105, 50), (123, 50), (114, 34)], fill=theme.shadow)

    return canvas


def make_die(
    theme: IconTheme,
    *,
    size: int = 220,
    fill: tuple[int, int, int] | None = None,
    pip_fill: tuple[int, int, int] | None = None,
    outline: tuple[int, int, int] | None = None,
    pattern: str = "5",
) -> Image.Image:
    fill = fill or theme.die_fill
    pip_fill = pip_fill or theme.die_pip
    outline = outline or theme.paper_front

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (int(size * 0.14), int(size * 0.16), int(size * 0.86), int(size * 0.88)),
        radius=int(size * 0.19),
        fill=(*theme.shadow, 118),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(10, size // 10)))
    canvas.alpha_composite(shadow)

    draw = ImageDraw.Draw(canvas)
    die_box = (int(size * 0.08), int(size * 0.08), int(size * 0.82), int(size * 0.82))
    draw.rounded_rectangle(die_box, radius=int(size * 0.18), fill=fill, outline=outline, width=max(4, size // 28))

    left, top, right, bottom = die_box
    width = right - left
    height = bottom - top
    offsets = {
        "2": [(0.28, 0.28), (0.72, 0.72)],
        "3": [(0.28, 0.28), (0.50, 0.50), (0.72, 0.72)],
        "4": [(0.28, 0.28), (0.72, 0.28), (0.28, 0.72), (0.72, 0.72)],
        "5": [(0.28, 0.28), (0.72, 0.28), (0.50, 0.50), (0.28, 0.72), (0.72, 0.72)],
    }[pattern]
    pip_radius = max(6, size // 22)
    for px, py in offsets:
        x = int(left + width * px)
        y = int(top + height * py)
        draw.ellipse((x - pip_radius, y - pip_radius, x + pip_radius, y + pip_radius), fill=pip_fill)

    return canvas


def make_sheet(theme: IconTheme, *, front: bool) -> Image.Image:
    width, height = (490, 612) if front else (420, 536)
    canvas = Image.new("RGBA", (width + 140, height + 150), (0, 0, 0, 0))

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_bbox = (52, 44, 52 + width, 44 + height)
    shadow_draw.rounded_rectangle(shadow_bbox, radius=56, fill=(*theme.shadow, 118 if front else 74))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=28 if front else 22))
    canvas.alpha_composite(shadow)

    draw = ImageDraw.Draw(canvas)
    body_bbox = (40, 28, 40 + width, 28 + height)
    draw.rounded_rectangle(
        body_bbox,
        radius=56,
        fill=theme.paper_front if front else theme.card_face,
        outline=theme.outline if front else theme.card_outline,
        width=18,
    )

    if not front:
        left, top, _, _ = body_bbox
        header_font = font(84)
        draw.text(
            (left + 92, top + 38),
            "FL",
            font=header_font,
            fill=theme.card_outline,
        )
        draw.rounded_rectangle(
            (left + 200, top + 58, left + 210, top + 104),
            radius=5,
            fill=theme.card_outline,
        )

        card_font = font(196)
        bbox = draw.textbbox((0, 0), "7", font=card_font)
        height_text = bbox[3] - bbox[1]
        left_inset = 56
        bottom_inset = 94
        draw.text(
            (left + left_inset, top + height - height_text - bottom_inset),
            "7",
            font=card_font,
            fill=theme.card_number,
        )
        return canvas

    draw_ll_tab(draw, theme, origin=(84, 76))
    draw_row(draw, theme, (108, 236), theme.row_a, 176)
    draw_row(draw, theme, (108, 334), theme.row_b, 146)
    draw_row(draw, theme, (108, 432), theme.row_c, 208)
    draw.rounded_rectangle((108, 530, 364, 558), radius=14, fill=theme.row_neutral)

    return canvas


def create_icon(theme: IconTheme) -> Image.Image:
    base = vertical_gradient(SIZE, theme.bg_top, theme.bg_bottom).convert("RGBA")

    add_soft_glow(base, theme.glow_primary, center=(752, 164), radius=290, alpha=84)
    add_soft_glow(base, theme.glow_secondary, center=(208, 836), radius=270, alpha=72)
    add_background_texture(base, theme)

    back_sheet = make_sheet(theme, front=False).rotate(-10, resample=Image.Resampling.BICUBIC, expand=True)
    back_sheet = scale_image(back_sheet, 1.08)
    base.alpha_composite(back_sheet, dest=(-10, 84))

    front_sheet = make_sheet(theme, front=True).rotate(3, resample=Image.Resampling.BICUBIC, expand=True)
    front_sheet = scale_image(front_sheet, 1.07)
    base.alpha_composite(front_sheet, dest=(264, 162))

    pencil = make_pencil(theme).rotate(22, resample=Image.Resampling.BICUBIC, expand=True)
    pencil = scale_image(pencil, 1.06)
    base.alpha_composite(pencil, dest=(612, 186))

    die_back_left = make_die(theme, size=148, fill=theme.row_neutral, pip_fill=theme.die_pip, outline=theme.outline, pattern="3")
    die_back_left = scale_image(die_back_left, 1.05)
    base.alpha_composite(die_back_left, dest=(606, 736))

    die = make_die(theme, size=220, pattern="5")
    die = scale_image(die, 1.08)
    base.alpha_composite(die, dest=(682, 690))

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
