#!/usr/bin/env python3
"""Render tasteful minimalist App Store marketing screenshots from raw captures.

Run on macOS so SF Pro Rounded is used for sublines (matching the iOS UI).
Produces exact App Store dimensions:
  - iPhone 6.9-inch: 1320 x 2868 (opaque RGB PNG)
  - iPad 13-inch:    2064 x 2752 (opaque RGB PNG)
"""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


REPO_ROOT = Path(__file__).resolve().parent.parent
NUNITO_BLACK = REPO_ROOT / "flip7calculator" / "Nunito-Black.ttf"
SF_ROUNDED_CANDIDATES = (
    "/System/Library/Fonts/SFNSRounded.ttf",
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
)


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


def load_body_font(size: int) -> ImageFont.FreeTypeFont:
    for candidate in SF_ROUNDED_CANDIDATES:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.truetype(str(NUNITO_BLACK), size=size)


def load_headline_font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(NUNITO_BLACK), size=size)


@dataclass(frozen=True)
class SlideSpec:
    source_name: str
    output_name: str
    headline: str
    subline: str
    accent_hex: str = "F0C14B"


IPHONE_SLIDES = (
    SlideSpec(
        source_name="live.png",
        output_name="01-live-scoring.png",
        headline="Fast round scoring",
        subline="Tap cards and modifiers as they hit the table.",
        accent_hex="6AA9E8",
    ),
    SlideSpec(
        source_name="live-bonus.png",
        output_name="02-states-and-bonus.png",
        headline="Clear player states",
        subline="See who banked, froze, busted, or hit 7 cards.",
        accent_hex="F0C14B",
    ),
    SlideSpec(
        source_name="stats.png",
        output_name="03-stats-charts.png",
        headline="Full game stats",
        subline="Score graphs, highlights, and round history.",
        accent_hex="F0C14B",
    ),
    SlideSpec(
        source_name="setup.png",
        output_name="04-quick-setup.png",
        headline="Quick game setup",
        subline="Add 2–8 players, pick a target, and deal.",
        accent_hex="6AA9E8",
    ),
    SlideSpec(
        source_name="game-over.png",
        output_name="05-game-over.png",
        headline="Final standings",
        subline="Review the scores or start a rematch in one tap.",
        accent_hex="F0C14B",
    ),
)

IPAD_SLIDES = (
    SlideSpec(
        source_name="live.png",
        output_name="01-live-split.png",
        headline="Made for the whole table",
        subline="Big player tiles and keypad on iPad.",
        accent_hex="6AA9E8",
    ),
    SlideSpec(
        source_name="live-bonus.png",
        output_name="02-states-and-bonus.png",
        headline="Clear player states",
        subline="Track banked hands, busts, freezes, and 7-card bonuses.",
        accent_hex="F0C14B",
    ),
    SlideSpec(
        source_name="stats.png",
        output_name="03-stats-charts.png",
        headline="Full game stats",
        subline="Score graphs, highlights, and round-by-round history.",
        accent_hex="F0C14B",
    ),
    SlideSpec(
        source_name="game-over.png",
        output_name="04-game-over.png",
        headline="Final standings",
        subline="Check the leaderboard or start a rematch in one tap.",
        accent_hex="6AA9E8",
    ),
)


def make_ambient_canvas(width: int, height: int, accent: tuple[int, int, int]) -> Image.Image:
    grid_w, grid_h = 180, int(180 * height / width)
    img = Image.new("RGB", (grid_w, grid_h))
    px = img.load()

    top_base = rgb("132642")
    bottom_base = rgb("08111E")
    glow_x = grid_w * 0.50
    glow_y = grid_h * 0.14
    glow_r = grid_w * 0.85

    for y in range(grid_h):
        ty = y / max(1, grid_h - 1)
        base = lerp_color(top_base, bottom_base, ty)
        for x in range(grid_w):
            d = math.hypot(x - glow_x, (y - glow_y) * 1.15) / glow_r
            glow = max(0.0, 1.0 - d) ** 2 * 0.13
            px[x, y] = lerp_color(base, accent, glow)

    return img.resize((width, height), resample=Image.Resampling.BICUBIC).convert("RGBA")


def round_image(image: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, image.width - 1, image.height - 1), radius=radius, fill=255)
    out = image.convert("RGBA")
    out.putalpha(mask)
    return out


def render_slide(
    raw_path: Path,
    out_path: Path,
    spec: SlideSpec,
    canvas_size: tuple[int, int],
    *,
    is_ipad: bool,
) -> None:
    cw, ch = canvas_size
    accent = rgb(spec.accent_hex)
    canvas = make_ambient_canvas(cw, ch, accent)
    draw = ImageDraw.Draw(canvas)

    max_text_width = cw - (140 if not is_ipad else 220)

    def fit_font(loader, text: str, start_size: int, min_size: int) -> ImageFont.FreeTypeFont:
        size = start_size
        while size > min_size:
            f = loader(size)
            bbox = draw.textbbox((0, 0), text, font=f)
            if (bbox[2] - bbox[0]) <= max_text_width:
                return f
            size -= 2
        return loader(min_size)

    headline_font = fit_font(load_headline_font, spec.headline, 112 if not is_ipad else 104, 68)
    subline_font = fit_font(load_body_font, spec.subline, 46 if not is_ipad else 44, 30)

    cx = cw // 2
    headline_y = 136 if not is_ipad else 112

    draw.text(
        (cx, headline_y),
        spec.headline,
        font=headline_font,
        fill=(248, 250, 253, 255),
        anchor="ma",
    )

    subline_y = headline_y + (134 if not is_ipad else 124)
    draw.text(
        (cx, subline_y),
        spec.subline,
        font=subline_font,
        fill=(182, 200, 224, 255),
        anchor="ma",
    )

    # Subtle minimal accent rule under subline
    rule_w = 84
    rule_y = subline_y + (76 if not is_ipad else 68)
    draw.rounded_rectangle(
        (cx - rule_w // 2, rule_y, cx + rule_w // 2, rule_y + 7),
        radius=4,
        fill=(*accent, 220),
    )

    raw = Image.open(raw_path).convert("RGBA")
    frame_top = rule_y + (54 if not is_ipad else 48)
    side_pad = 92 if not is_ipad else 126
    bottom_pad = 64 if not is_ipad else 68

    avail_w = cw - side_pad * 2
    avail_h = ch - frame_top - bottom_pad
    scale = min(avail_w / raw.width, avail_h / raw.height)
    shot_w = int(round(raw.width * scale))
    shot_h = int(round(raw.height * scale))
    resized = raw.resize((shot_w, shot_h), resample=Image.Resampling.LANCZOS)

    bezel = 18 if not is_ipad else 22
    outer_w = shot_w + bezel * 2
    outer_h = shot_h + bezel * 2
    outer_x = (cw - outer_w) // 2
    outer_y = frame_top
    outer_radius = 86 if not is_ipad else 62
    inner_radius = outer_radius - bezel + 4

    shadow_layer = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow_layer)
    sdraw.rounded_rectangle(
        (outer_x, outer_y + 24, outer_x + outer_w, outer_y + outer_h + 24),
        radius=outer_radius,
        fill=(2, 6, 14, 150),
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=38))
    canvas.alpha_composite(shadow_layer)

    shell = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    shdraw = ImageDraw.Draw(shell)
    shdraw.rounded_rectangle(
        (outer_x, outer_y, outer_x + outer_w, outer_y + outer_h),
        radius=outer_radius,
        fill=(12, 20, 32, 255),
        outline=(110, 142, 184, 96),
        width=4,
    )
    canvas.alpha_composite(shell)

    rounded_shot = round_image(resized, inner_radius)
    canvas.alpha_composite(rounded_shot, dest=(outer_x + bezel, outer_y + bezel))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path, format="PNG", optimize=True)
    print(f"Rendered {out_path} ({cw}x{ch})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--raw-dir", type=Path, required=True, help="Directory with iphone/ and ipad/ raw captures")
    parser.add_argument("--out-dir", type=Path, default=REPO_ROOT / "AppStoreAssets" / "1.4")
    args = parser.parse_args()

    iphone_raw = args.raw_dir / "iphone"
    ipad_raw = args.raw_dir / "ipad"

    for spec in IPHONE_SLIDES:
        src = iphone_raw / spec.source_name
        if src.exists():
            render_slide(src, args.out_dir / "iPhone-6.9" / spec.output_name, spec, (1320, 2868), is_ipad=False)

    for spec in IPAD_SLIDES:
        src = ipad_raw / spec.source_name
        if src.exists():
            render_slide(src, args.out_dir / "iPad-13" / spec.output_name, spec, (2064, 2752), is_ipad=True)


if __name__ == "__main__":
    main()
