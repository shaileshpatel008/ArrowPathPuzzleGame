"""Builds the Google Play listing graphics from real app screenshots.

1. Render the screens:
     flutter test tool/screenshots/screens_test.dart --update-goldens
2. Build the store assets (needs Python 3 + Pillow: pip install pillow):
     python3 tool/store_assets/make_store_assets.py

Output (store_listing/):
  screenshots/01_*.png ... 08_*.png   1080x1920 phone screenshots (9:16)
  feature_graphic_1024x500.png        feature graphic
  icon_512.png                        app icon (copied from branding)
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SHOTS = os.path.join(ROOT, 'tool', 'screenshots', 'out', 'store_1080x2160')
OUT = os.path.join(ROOT, 'store_listing')
FONT_BOLD = os.path.join(ROOT, 'assets', 'fonts', 'SpaceGrotesk-700.ttf')
FONT_BODY = os.path.join(ROOT, 'assets', 'fonts', 'Inter-500.ttf')

BLUE = (46, 75, 255)
INK = (16, 19, 28)
ORANGE = (232, 89, 12)
TEAL = (14, 159, 142)

# (source screenshot, caption, sub caption, background)
SLIDES = [
    ('05_game_hint', 'Tap an arrow.\nClear its path.', 'Hints show you a safe move', BLUE),
    ('06_game_crash', 'Find the right order', 'Watch out for crashes!', INK),
    ('04_levels', '200 levels to master', '8 chapters, from 4×4 to 9×9', BLUE),
    ('10_daily', 'A puzzle every day', 'Keep your daily streak alive', INK),
    ('07_level_cleared', 'Earn all 3 stars', 'Clear the board without a crash', BLUE),
    ('11_themes', 'Pick your style', 'Beautiful themes, dark mode included', INK),
    ('16_home_midnight', 'Relax and think ahead', 'Plays offline, no account needed', BLUE),
    ('02_onboarding', 'Easy to learn', 'Hard to put down', INK),
]

W, H = 1080, 1920


def wrap(draw, text, font, max_w):
    lines = []
    for para in text.split('\n'):
        words, line = para.split(), ''
        for w in words:
            test = (line + ' ' + w).strip()
            if draw.textlength(test, font=font) <= max_w:
                line = test
            else:
                lines.append(line)
                line = w
        lines.append(line)
    return lines


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius, fill=255)
    out = Image.new('RGBA', img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def slide(src, caption, sub, bg, index):
    canvas = Image.new('RGB', (W, H), bg)
    d = ImageDraw.Draw(canvas)
    # soft decorative tiles
    accent = [(255, 255, 255, 18), (255, 255, 255, 12)]
    deco = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(deco)
    for (x, y, s), c in zip([(60, 80, 90), (900, 220, 120), (40, 1500, 130), (920, 1650, 90)], accent * 2):
        dd.rounded_rectangle([x, y, x + s, y + s], s // 4, fill=c)
    canvas.paste(deco, (0, 0), deco)

    title_font = ImageFont.truetype(FONT_BOLD, 84)
    sub_font = ImageFont.truetype(FONT_BODY, 40)
    y = 120
    for line in wrap(d, caption, title_font, W - 140):
        tw = d.textlength(line, font=title_font)
        d.text(((W - tw) / 2, y), line, font=title_font, fill=(255, 255, 255))
        y += 100
    y += 10
    tw = d.textlength(sub, font=sub_font)
    d.text(((W - tw) / 2, y), sub, font=sub_font, fill=(214, 221, 255) if bg == BLUE else (180, 186, 203))

    shot = Image.open(os.path.join(SHOTS, src + '.png')).convert('RGB')
    phone_h = H - (y + 110) - 60
    phone_w = int(shot.width * phone_h / shot.height)
    shot = shot.resize((phone_w, phone_h), Image.LANCZOS)
    bezel = 16
    frame = Image.new('RGBA', (phone_w + bezel * 2, phone_h + bezel * 2), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle([0, 0, frame.width - 1, frame.height - 1], 64, fill=(11, 13, 20, 255))
    frame.paste(rounded(shot, 50), (bezel, bezel), rounded(shot, 50))
    px = (W - frame.width) // 2
    py = y + 110
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([px + 10, py + 24, px + frame.width + 10, py + frame.height + 24], 64, fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.paste(shadow, (0, 0), shadow)
    canvas.paste(frame, (px, py), frame)
    name = f'{index:02d}_{src.split("_", 1)[1]}.png'
    canvas.save(os.path.join(OUT, 'screenshots', name), optimize=True)
    return name


def feature_graphic():
    fg = Image.new('RGB', (1024, 500), INK)
    d = ImageDraw.Draw(fg)
    for x, y, c in [(70, 50, BLUE), (900, 70, ORANGE), (120, 400, TEAL), (920, 380, BLUE), (560, 430, ORANGE)]:
        d.rounded_rectangle([x, y, x + 54, y + 54], 14, fill=tuple(int(v * .35 + 27 * .65) for v in c))
    icon = Image.open(os.path.join(ROOT, 'assets', 'branding', 'logo_mark.png')).convert('RGBA').resize((280, 280), Image.LANCZOS)
    fg.paste(icon, (90, 110), icon)
    big = ImageFont.truetype(FONT_BOLD, 76)
    small = ImageFont.truetype(FONT_BODY, 32)
    d.text((420, 150), 'Arrow Path', font=big, fill=(255, 255, 255))
    d.text((420, 232), 'Puzzle', font=big, fill=(255, 255, 255))
    d.text((424, 335), 'Tap. Slide. Clear the board.', font=small, fill=(180, 186, 203))
    fg.save(os.path.join(OUT, 'feature_graphic_1024x500.png'), optimize=True)


def icon():
    src = Image.open(os.path.join(ROOT, 'assets', 'branding', 'app_icon.png')).convert('RGB')
    src.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, 'icon_512.png'), optimize=True)


def main():
    if not os.path.isdir(SHOTS):
        sys.exit('Run the screenshot test first (see the top of this file).')
    os.makedirs(os.path.join(OUT, 'screenshots'), exist_ok=True)
    names = [slide(s, c, sub, bg, i + 1) for i, (s, c, sub, bg) in enumerate(SLIDES)]
    feature_graphic()
    icon()
    print('Created:', ', '.join(names), '+ feature graphic + icon')


if __name__ == '__main__':
    main()
