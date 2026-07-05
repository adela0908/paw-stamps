#!/usr/bin/env python3
"""Generate iOS assets: 1024px app icon (scaled version of the web icon art)
and tiny WAV sound effects. Pure stdlib, no dependencies.

Run from the ios/ directory:  python3 scripts/make_assets.py
"""
import math, os, struct, wave, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
APPDIR = os.path.join(HERE, "..", "PawStamps")

# ---------------------------------------------------------------- icon
S = 1024
U = S / 180.0  # scale factor from the 180px design space
CREAM = (255, 246, 224)
INK = (43, 33, 23)
WHITE = (255, 255, 255)
RED = (232, 80, 58)

px = [[CREAM for _ in range(S)] for _ in range(S)]

def in_ellipse(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0

def ellipse(cx, cy, rx, ry, color, ymin=-1):
    cx, cy, rx, ry, ymin = cx * U, cy * U, rx * U, ry * U, ymin * U
    for y in range(max(0, int(cy - ry - 1)), min(S, int(cy + ry + 2))):
        if ymin >= 0 and y + .5 < ymin:
            continue
        for x in range(max(0, int(cx - rx - 1)), min(S, int(cx + rx + 2))):
            if in_ellipse(x + .5, y + .5, cx, cy, rx, ry):
                px[y][x] = color

def tri(p1, p2, p3, color):
    p1 = (p1[0] * U, p1[1] * U); p2 = (p2[0] * U, p2[1] * U); p3 = (p3[0] * U, p3[1] * U)
    def edge(a, b, p):
        return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
    xs = [p1[0], p2[0], p3[0]]; ys = [p1[1], p2[1], p3[1]]
    for y in range(max(0, int(min(ys))), min(S, int(max(ys)) + 1)):
        for x in range(max(0, int(min(xs))), min(S, int(max(xs)) + 1)):
            p = (x + .5, y + .5)
            d1, d2, d3 = edge(p1, p2, p), edge(p2, p3, p), edge(p3, p1, p)
            if not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0)):
                px[y][x] = color

def stroke_quad(p0, p1, p2, r, color):
    steps = 200
    for i in range(steps + 1):
        t = i / steps
        x = (1-t)**2*p0[0] + 2*(1-t)*t*p1[0] + t**2*p2[0]
        y = (1-t)**2*p0[1] + 2*(1-t)*t*p1[1] + t**2*p2[1]
        ellipse(x, y, r, r, color)

# ears
tri((38, 78), (50, 30), (80, 58), INK)
tri((142, 78), (130, 30), (100, 58), INK)
tri((46, 70), (54, 42), (72, 58), WHITE)
tri((134, 70), (126, 42), (108, 58), WHITE)
# blob body
ellipse(90, 110, 68, 60, INK)
ellipse(90, 110, 61, 53, WHITE)
# eyes
ellipse(60, 90, 7, 9, INK)
ellipse(120, 90, 7, 9, INK)
# wavy mouth
stroke_quad((64, 114), (77, 130), (90, 120), 4, INK)
stroke_quad((90, 120), (103, 130), (116, 114), 4, INK)
# red paw bottom-right
ellipse(150, 156, 13, 10, RED)
ellipse(135, 141, 5.5, 6.5, RED)
ellipse(145, 135, 5.5, 6.5, RED)
ellipse(155, 135, 5.5, 6.5, RED)
ellipse(165, 141, 5.5, 6.5, RED)

def write_png(path, pixels, size):
    raw = b''.join(b'\x00' + b''.join(struct.pack('BBB', *p) for p in row) for row in pixels)
    def chunk(tag, data):
        c = tag + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    ihdr = struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', ihdr))
        f.write(chunk(b'IDAT', zlib.compress(raw, 9)))
        f.write(chunk(b'IEND', b''))

icon_dir = os.path.join(APPDIR, "Assets.xcassets", "AppIcon.appiconset")
os.makedirs(icon_dir, exist_ok=True)
write_png(os.path.join(icon_dir, "icon-1024.png"), px, S)
with open(os.path.join(icon_dir, "Contents.json"), "w") as f:
    f.write('''{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''')

# asset catalog root + launch color
root = os.path.join(APPDIR, "Assets.xcassets")
with open(os.path.join(root, "Contents.json"), "w") as f:
    f.write('{\n  "info" : { "author" : "xcode", "version" : 1 }\n}\n')
launch = os.path.join(root, "LaunchBackground.colorset")
os.makedirs(launch, exist_ok=True)
with open(os.path.join(launch, "Contents.json"), "w") as f:
    f.write('''{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.878", "green" : "0.965", "red" : "1.000" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
''')
print("wrote app icon + asset catalog")

# ---------------------------------------------------------------- sounds
RATE = 22050

def render(notes, path):
    """notes: list of (freq, start_s, dur_s, wave_type, gain)"""
    total = max(s + d for _, s, d, _, _ in notes) + 0.05
    n = int(total * RATE)
    buf = [0.0] * n
    for freq, start, dur, kind, gain in notes:
        i0 = int(start * RATE)
        for i in range(int(dur * RATE)):
            t = i / RATE
            phase = 2 * math.pi * freq * t
            if kind == "square":
                v = 1.0 if math.sin(phase) >= 0 else -1.0
            elif kind == "saw":
                v = 2.0 * ((freq * t) % 1.0) - 1.0
            else:
                v = math.sin(phase)
            env = math.exp(-4.5 * t / dur)
            j = i0 + i
            if j < n:
                buf[j] += v * gain * env
    frames = b''.join(struct.pack('<h', max(-32767, min(32767, int(s * 32767)))) for s in buf)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)

snd = os.path.join(APPDIR, "Sounds")
os.makedirs(snd, exist_ok=True)
render([(520, 0, 0.06, "sine", 0.35)], os.path.join(snd, "tap.wav"))
render([(660, 0, 0.09, "square", 0.22), (880, 0.07, 0.12, "square", 0.22)],
       os.path.join(snd, "pop.wav"))
render([(523, 0, 0.14, "square", 0.20), (659, 0.12, 0.14, "square", 0.20),
        (784, 0.24, 0.14, "square", 0.20), (1047, 0.36, 0.32, "square", 0.22)],
       os.path.join(snd, "fanfare.wav"))
render([(220, 0, 0.15, "saw", 0.20), (180, 0.13, 0.2, "saw", 0.20)],
       os.path.join(snd, "no.wav"))
print("wrote sounds: tap, pop, fanfare, no")
