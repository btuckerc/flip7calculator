#!/usr/bin/env python3
"""Render cohesive App Store Product Page Header and Search Results creative assets.

Produces exact App Store Connect Creative Assets (opaque RGB PNG, no alpha):
  - Product Page Header: 3840 x 1646 (21:9), Apple art-safe rect 1646x661 @ (1097, 493)
  - Search Results:      3840 x 2560 (3:2),  Apple art-safe rect 2168x1030 @ (836, 765)

Design tokens match icon/generate_icon_variants.py (DARK theme) and
scripts/render-appstore-screenshots.py (twilight indigo-navy + subtle cyan/purple/gold).
Zero text in either asset so en-US and es-MX share identical art with zero trademark risk.
"""

from __future__ import annotations

import argparse
import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


REPO_ROOT = Path(__file__).resolve().parent.parent
NUNITO_BLACK = REPO_ROOT / "flip7calculator" / "Nunito-Black.ttf"

# Exact Apple Creative Assets Specifications safe-area rects (x0, y0, x1, y1)
HEADER_SIZE = (3840, 1646)
HEADER_SAFE_RECT = (1097, 493, 1097 + 1646, 493 + 661)

SEARCH_SIZE = (3840, 2560)
SEARCH_SAFE_RECT = (836, 765, 836 + 2168, 765 + 1030)


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


def scale_rgb(c: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    return (
        max(0, min(255, int(round(c[0] * factor)))),
        max(0, min(255, int(round(c[1] * factor)))),
        max(0, min(255, int(round(c[2] * factor)))),
    )


def make_vertical_gradient(
    width: int, height: int, top_rgb: tuple[int, int, int], bottom_rgb: tuple[int, int, int]
) -> Image.Image:
    strip = Image.new("RGB", (1, 256))
    px = strip.load()
    for y in range(256):
        px[0, y] = lerp_color(top_rgb, bottom_rgb, y / 255.0)
    return strip.resize((width, height), resample=Image.Resampling.BILINEAR).convert("RGBA")


def make_rounded_mask(
    size: tuple[int, int], box: tuple[int, int, int, int], radius: int
) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(box, radius=radius, fill=255)
    return mask


def round_image(image: Image.Image, radius: int) -> Image.Image:
    mask = make_rounded_mask(image.size, (0, 0, image.width - 1, image.height - 1), radius)
    out = image.convert("RGBA")
    out.putalpha(mask)
    return out


def add_subtle_dither(canvas: Image.Image, seed: int = 7) -> Image.Image:
    """Apply tiny deterministic +/-1 LSB dither to prevent 8-bit dark gradient banding."""
    w, h = canvas.size
    rng = random.Random(seed)
    # Tile a 128x128 dither field for speed and crisp uniformity
    tile_s = 128
    noise_rgb = bytes(
        (128 + (rng.choice((-1, 1)) if rng.random() < 0.35 else 0))
        for _ in range(tile_s * tile_s)
    )
    # Fast per-channel subtle dither using PIL point math on tiled layer isn't signed,
    # so apply directly to a downscaled 1/2 grid or fast RGB buffer? Actually at 3840x2560
    # 128x128 tiled bytearray addition in Python takes ~0.2s via bytes.translate? Let's keep it clean.
    base = canvas.convert("RGB")
    raw = bytearray(base.tobytes())
    # Apply deterministic sparse +/-1 LSB every ~11 bytes so it's ultra-fast and band-free
    offsets = [rng.choice((-1, 0, 1)) for _ in range(257)]
    n = len(raw)
    for i in range(0, n, 3):
        d = offsets[(i * 7 + (i // 3) * 13) % 257]
        if d:
            for c in range(3):
                v = raw[i + c] + d
                if 0 <= v <= 255:
                    raw[i + c] = v
    return Image.frombytes("RGB", (w, h), bytes(raw)).convert("RGBA")


def make_ground(
    width: int,
    height: int,
    glows: list[tuple[tuple[int, int, int], float, float, float, float]],
    *,
    horizontal_vignette: float = 1.0,
    bottom_handoff_px: int = 0,
    bottom_handoff_rgb: tuple[int, int, int] = (7, 8, 24),
) -> Image.Image:
    """Render smooth ambient ground matching scripts/render-appstore-screenshots.py."""
    grid_w = 240
    grid_h = max(64, int(round(grid_w * height / width)))
    img = Image.new("RGB", (grid_w, grid_h))
    px = img.load()

    top_base = rgb("151F47")
    bottom_base = rgb("0A0B1F")
    handoff_frac = bottom_handoff_px / max(1, height)

    # Convert glows to grid coordinates
    grid_glows = [
        (color, gx_frac * grid_w, gy_frac * grid_h, gr_frac * grid_w, strength)
        for (color, gx_frac, gy_frac, gr_frac, strength) in glows
    ]

    for y in range(grid_h):
        ty = y / max(1, grid_h - 1)
        base_row = lerp_color(top_base, bottom_base, ty)
        for x in range(grid_w):
            tx = x / max(1, grid_w - 1)
            color = base_row
            if horizontal_vignette < 1.0:
                edge_dist = max(0.0, abs(tx - 0.5) - 0.25) / 0.25
                vig = 1.0 - (1.0 - horizontal_vignette) * (edge_dist ** 1.6)
                color = scale_rgb(color, vig)
            for gcolor, gx, gy, gr, strength in grid_glows:
                d = math.hypot(x - gx, (y - gy) * 1.08) / max(1e-6, gr)
                if d < 1.0:
                    w_glow = ((1.0 - d) ** 2) * strength
                    color = lerp_color(color, gcolor, w_glow)
            if handoff_frac > 0.0 and ty > (1.0 - handoff_frac):
                ht = (ty - (1.0 - handoff_frac)) / handoff_frac
                color = lerp_color(color, bottom_handoff_rgb, ht * ht)
            px[x, y] = color

    return img.resize((width, height), resample=Image.Resampling.BICUBIC).convert("RGBA")


def make_card(
    width: int,
    *,
    face_top: tuple[int, int, int],
    face_bottom: tuple[int, int, int],
    border_rgb: tuple[int, int, int],
    border_alpha: int,
    border_ratio: float,
    has_seven: bool = False,
    shadow_alpha: int = 115,
    extra_contact_shadow: bool = False,
    rotation_deg: float = 0.0,
    scale: int = 4,
) -> Image.Image:
    """Render a 4x-supersampled card matching icon/generate_icon_variants.py DARK theme."""
    w = width * scale
    h = int(round(width * 1.3488)) * scale
    radius = int(round(width * 0.151)) * scale
    border_w = max(1, int(round(width * border_ratio))) * scale
    pad = int(round(width * 0.34)) * scale

    cw = w + pad * 2
    ch = h + pad * 2
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))

    # Optional deeper contact shadow for hero card
    if extra_contact_shadow:
        contact = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        cdraw = ImageDraw.Draw(contact)
        cdraw.rounded_rectangle(
            (pad, pad + int(round(width * 0.135)) * scale, pad + w, pad + h + int(round(width * 0.135)) * scale),
            radius=radius,
            fill=(*rgb("010408"), 65),
        )
        contact = contact.filter(ImageFilter.GaussianBlur(radius=int(round(width * 0.155)) * scale))
        canvas.alpha_composite(contact)

    # Directional upper-left key-light shadow (points down-right ~65 deg)
    sx = int(round(width * 0.016)) * scale
    sy = int(round(width * 0.035)) * scale
    sblur = max(1, int(round(width * 0.043)) * scale)
    shadow = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        (pad + sx, pad + sy, pad + w + sx, pad + h + sy),
        radius=radius,
        fill=(*rgb("010408"), shadow_alpha),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=sblur))
    canvas.alpha_composite(shadow)

    # Card gradient body
    card_box = (pad, pad, pad + w, pad + h)
    grad = make_vertical_gradient(w, h, face_top, face_bottom)
    fill_layer = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    fill_layer.paste(grad, (pad, pad))
    fill_layer.putalpha(make_rounded_mask((cw, ch), card_box, radius))
    canvas.alpha_composite(fill_layer)

    # Subtle 1px inner top-left specular bevel inside border
    bevel = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    bdraw = ImageDraw.Draw(bevel)
    inset = border_w + scale
    bdraw.rounded_rectangle(
        (pad + inset, pad + inset, pad + w - inset, pad + h - inset),
        radius=max(1, radius - inset),
        outline=(255, 255, 255, 26),
        width=max(1, scale),
    )
    canvas.alpha_composite(bevel)

    # Crisp card border
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        card_box,
        radius=radius,
        outline=(*border_rgb, border_alpha),
        width=border_w,
    )

    if has_seven:
        font_size = int(round(width * 1.037)) * scale
        font = ImageFont.truetype(str(NUNITO_BLACK), size=font_size)
        cx = pad + w // 2 + int(round(width * -0.008)) * scale
        cy = pad + h // 2 + int(round(width * 0.023)) * scale

        # Delicate cyan misregistered-print shadow echoing the screenshot accent rule
        ox = int(round(width * 0.009)) * scale
        oy = int(round(width * 0.006)) * scale
        cyan_layer = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        cdraw = ImageDraw.Draw(cyan_layer)
        cdraw.text(
            (cx + ox, cy + oy),
            "7",
            font=font,
            fill=(*rgb("22D3EE"), 52),
            anchor="mm",
        )
        canvas.alpha_composite(cyan_layer)

        # Primary warm cream 7
        draw.text(
            (cx, cy),
            "7",
            font=font,
            fill=(*rgb("FFFBF2"), 255),
            anchor="mm",
        )

    if abs(rotation_deg) > 1e-3:
        canvas = canvas.rotate(rotation_deg, resample=Image.Resampling.BICUBIC, expand=True)

    out_w = max(1, int(round(canvas.width / scale)))
    out_h = max(1, int(round(canvas.height / scale)))
    return canvas.resize((out_w, out_h), resample=Image.Resampling.LANCZOS)


def make_ghost_card(
    width: int,
    *,
    rotation_deg: float,
    blur_radius: int = 10,
    opacity: float = 0.50,
) -> Image.Image:
    """Soft out-of-focus peripheral card for depth of field in the croppable auxiliary zone."""
    card = make_card(
        width,
        face_top=rgb("15244F"),
        face_bottom=rgb("0D1633"),
        border_rgb=rgb("9CC4F0"),
        border_alpha=36,
        border_ratio=0.018,
        has_seven=False,
        shadow_alpha=55,
        rotation_deg=rotation_deg,
        scale=2,
    )
    card = card.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    if opacity < 1.0:
        r, g, b, a = card.split()
        a = a.point(lambda v: int(round(v * opacity)))
        card = Image.merge("RGBA", (r, g, b, a))
    return card


def paste_centered(canvas: Image.Image, layer: Image.Image, cx: int, cy: int) -> None:
    x = cx - layer.width // 2
    y = cy - layer.height // 2
    canvas.alpha_composite(layer, dest=(x, y))


def render_header(out_path: Path, debug_dir: Path | None = None) -> Image.Image:
    """Render Product Page Header (3840 x 1646, 21:9 opaque RGB PNG) — 'The Deal'."""
    cw, ch = HEADER_SIZE
    canvas = make_ground(
        cw,
        ch,
        glows=[
            (rgb("A855F7"), 0.50, 0.34, 0.40, 0.14),  # Electric purple overhead key glow
            (rgb("F0C14B"), 0.58, 0.60, 0.24, 0.08),  # Warm gold rim glow behind hero 7
            (rgb("22D3EE"), 0.88, 0.86, 0.30, 0.05),  # Subtle cyan Spider-Verse corner glint
        ],
        horizontal_vignette=0.76,
        bottom_handoff_px=160,
        bottom_handoff_rgb=rgb("070818"),
    )

    # Subtle radial table pool grounding the three-card fan
    pool = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    pdraw = ImageDraw.Draw(pool)
    pdraw.ellipse((1920 - 860, 1120 - 170, 1920 + 860, 1120 + 170), fill=(*rgb("1F316D"), 92))
    pool = pool.filter(ImageFilter.GaussianBlur(radius=95))
    canvas.alpha_composite(pool)

    # Soft peripheral depth-of-field ghost cards (auxiliary area only)
    ghost_left = make_ghost_card(560, rotation_deg=28.0, blur_radius=10, opacity=0.48)
    ghost_right = make_ghost_card(560, rotation_deg=-22.0, blur_radius=10, opacity=0.48)
    paste_centered(canvas, ghost_left, 620, 720)
    paste_centered(canvas, ghost_right, 3230, 960)

    # Focal sculptural 3-card fan — all inside Apple's 1646x661 safe rect (1097..2743, 493..1154)
    # Sized with ~25px vertical breathing room so extreme 3840x661 strip crops never kiss the gold rim
    third_card = make_card(
        352,
        face_top=rgb("1B3352"),
        face_bottom=rgb("12243D"),
        border_rgb=rgb("9CC4F0"),
        border_alpha=75,
        border_ratio=0.021,
        has_seven=False,
        shadow_alpha=105,
        rotation_deg=24.0,
    )
    back_card = make_card(
        385,
        face_top=rgb("244775"),
        face_bottom=rgb("183254"),
        border_rgb=rgb("9CC4F0"),
        border_alpha=120,
        border_ratio=0.021,
        has_seven=False,
        shadow_alpha=115,
        rotation_deg=12.0,
    )
    hero_card = make_card(
        424,
        face_top=rgb("2D5282"),
        face_bottom=rgb("1F3B61"),
        border_rgb=rgb("F2C755"),
        border_alpha=240,
        border_ratio=0.029,
        has_seven=True,
        shadow_alpha=130,
        extra_contact_shadow=True,
        rotation_deg=-6.0,
    )

    paste_centered(canvas, third_card, 1725, 848)
    paste_centered(canvas, back_card, 1882, 836)
    paste_centered(canvas, hero_card, 2058, 823)

    canvas = add_subtle_dither(canvas, seed=17)
    final_rgb = canvas.convert("RGB")
    assert final_rgb.size == HEADER_SIZE and final_rgb.mode == "RGB"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    final_rgb.save(out_path, format="PNG", optimize=True)
    print(f"Rendered {out_path} ({cw}x{ch}, RGB)")

    if debug_dir is not None:
        debug_dir.mkdir(parents=True, exist_ok=True)
        # Safe-area overlay proof
        ov = final_rgb.copy()
        od = ImageDraw.Draw(ov)
        od.rectangle(HEADER_SAFE_RECT, outline=(34, 211, 238), width=6)
        ov.resize((1920, 823), Image.Resampling.LANCZOS).save(debug_dir / "header-safe-overlay.png")
        # Square center crop proof (1646x1646)
        sq_x0 = (cw - ch) // 2
        final_rgb.crop((sq_x0, 0, sq_x0 + ch, ch)).resize((900, 900), Image.Resampling.LANCZOS).save(
            debug_dir / "header-crop-square-1646x1646.png"
        )
        # Wide strip center crop proof (3840x661)
        final_rgb.crop((0, HEADER_SAFE_RECT[1], cw, HEADER_SAFE_RECT[3])).resize(
            (1920, 331), Image.Resampling.LANCZOS
        ).save(debug_dir / "header-crop-strip-3840x661.png")

    return final_rgb


def apply_bottom_fade(
    canvas: Image.Image, fade_height: int, color: tuple[int, int, int], max_alpha: int
) -> None:
    cw, ch = canvas.size
    strip = Image.new("RGBA", (1, fade_height))
    spx = strip.load()
    for y in range(fade_height):
        t = y / max(1, fade_height - 1)
        a = int(round((t ** 1.45) * max_alpha))
        spx[0, y] = (*color, a)
    fade_layer = strip.resize((cw, fade_height), resample=Image.Resampling.BILINEAR)
    canvas.alpha_composite(fade_layer, dest=(0, ch - fade_height))


def render_search(raw_live_bonus: Path, out_path: Path, debug_dir: Path | None = None) -> Image.Image:
    """Render Search Results Asset (3840 x 2560, 3:2 opaque RGB PNG) — 'Scoreboard + the 7'."""
    cw, ch = SEARCH_SIZE
    canvas = make_ground(
        cw,
        ch,
        glows=[
            (rgb("A855F7"), 0.50, 0.14, 0.48, 0.13),  # Electric purple top glow (matches screenshots)
            (rgb("F0C14B"), 0.32, 0.50, 0.26, 0.10),  # Warm gold glow behind hero 7 card pair
            (rgb("22D3EE"), 0.88, 0.86, 0.36, 0.05),  # Subtle cyan corner glow (matches screenshots)
        ],
    )

    # Load native 1320x2868 live-bonus capture and crop below 9:41 status bar
    raw = Image.open(raw_live_bonus).convert("RGBA")
    assert raw.size == (1320, 2868), f"Unexpected raw capture size: {raw.size}"

    # Crop from y=178 (cleanly below status bar, keeping "Round 5" nav row) to y=2290
    crop_top = 178
    crop_bottom = 2290
    cropped = raw.crop((0, crop_top, raw.width, crop_bottom))

    # 1:1 native retina scale (zero resampling blur): 1320 wide x 2112 tall
    # Screen at (1676, 578) places the 2x2 Miles/Ned/MJ/Peter tiles at:
    #   x = 1724..2948 (inside safe x <= 3004)
    #   y = 769..1807  (Miles/Ned tops sit cleanly inside safe y >= 765!)
    # Plus gold +15 badge at y~1868 and Bank/Bust/Freeze pills at y~1957..2064!
    screen_x = 1676
    screen_y = 578
    bezel = 22
    outer_x = screen_x - bezel
    outer_y = screen_y - bezel
    outer_w = cropped.width + bezel * 2
    outer_h = cropped.height + bezel * 2 + 120  # bleeds cleanly past bottom edge
    outer_radius = 104
    inner_radius = outer_radius - bezel + 4

    # Grounded phone drop shadow
    pshadow = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    psdraw = ImageDraw.Draw(pshadow)
    psdraw.rounded_rectangle(
        (outer_x + 18, outer_y + 44, outer_x + outer_w + 18, outer_y + outer_h + 44),
        radius=outer_radius,
        fill=(*rgb("02060E"), 165),
    )
    pshadow = pshadow.filter(ImageFilter.GaussianBlur(radius=90))
    canvas.alpha_composite(pshadow)

    # Phone shell (matching scripts/render-appstore-screenshots.py)
    shell = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    shdraw = ImageDraw.Draw(shell)
    shdraw.rounded_rectangle(
        (outer_x, outer_y, outer_x + outer_w, outer_y + outer_h),
        radius=outer_radius,
        fill=(12, 20, 32, 255),
        outline=(139, 124, 246, 92),
        width=6,
    )
    canvas.alpha_composite(shell)

    # Composite rounded native UI screen
    rounded_ui = round_image(cropped, inner_radius)
    canvas.alpha_composite(rounded_ui, dest=(screen_x, screen_y))

    # Dissolve the bottom edge of the phone smoothly into the dark twilight ground
    apply_bottom_fade(canvas, fade_height=240, color=rgb("0A0B1F"), max_alpha=215)

    # Sculpted 2-card '7' pair overlapping the phone's left bezel (x=1654) for instant recognition
    back_card = make_card(
        575,
        face_top=rgb("244775"),
        face_bottom=rgb("183254"),
        border_rgb=rgb("9CC4F0"),
        border_alpha=120,
        border_ratio=0.021,
        has_seven=False,
        shadow_alpha=120,
        rotation_deg=10.0,
    )
    hero_card = make_card(
        636,
        face_top=rgb("2D5282"),
        face_bottom=rgb("1F3B61"),
        border_rgb=rgb("F2C755"),
        border_alpha=242,
        border_ratio=0.029,
        has_seven=True,
        shadow_alpha=138,
        extra_contact_shadow=True,
        rotation_deg=-8.0,
    )

    # Placed so both the back card and hero '7' card sit cleanly inside Apple's safe rect
    # (836..3004, 765..1795) and overlap the phone's left bezel by ~55px with cast shadow depth
    paste_centered(canvas, back_card, 1196, 1318)
    paste_centered(canvas, hero_card, 1362, 1284)

    canvas = add_subtle_dither(canvas, seed=29)
    final_rgb = canvas.convert("RGB")
    assert final_rgb.size == SEARCH_SIZE and final_rgb.mode == "RGB"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    final_rgb.save(out_path, format="PNG", optimize=True)
    print(f"Rendered {out_path} ({cw}x{ch}, RGB)")

    if debug_dir is not None:
        debug_dir.mkdir(parents=True, exist_ok=True)
        ov = final_rgb.copy()
        od = ImageDraw.Draw(ov)
        od.rectangle(SEARCH_SAFE_RECT, outline=(34, 211, 238), width=8)
        ov.resize((1920, 1280), Image.Resampling.LANCZOS).save(debug_dir / "search-safe-overlay.png")
        final_rgb.resize((384, 256), Image.Resampling.LANCZOS).save(debug_dir / "search-thumb-384x256.png")
        final_rgb.resize((192, 128), Image.Resampling.LANCZOS).save(debug_dir / "search-thumb-192x128.png")

    return final_rgb


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--raw-live-bonus",
        type=Path,
        required=True,
        help="Path to native 1320x2868 iPhone live-bonus.png capture",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=REPO_ROOT / "AppStoreAssets" / "1.4" / "Creative",
    )
    parser.add_argument(
        "--debug-safe-area",
        type=Path,
        default=None,
        help="Optional directory for safe-area overlays, crop proofs, and thumbnail proofs",
    )
    args = parser.parse_args()

    render_header(args.out_dir / "header-3840x1646.png", debug_dir=args.debug_safe_area)
    render_search(
        args.raw_live_bonus,
        args.out_dir / "search-3840x2560.png",
        debug_dir=args.debug_safe_area,
    )


if __name__ == "__main__":
    main()
