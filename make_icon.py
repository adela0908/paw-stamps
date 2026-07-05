#!/usr/bin/env python3
"""Generate apple-touch-icon.png (180x180) — Battle Cats style blob cat, no deps."""
import struct, zlib

W = H = 180
CREAM = (255, 246, 224)
INK = (43, 33, 23)
WHITE = (255, 255, 255)
RED = (232, 80, 58)

px = [[CREAM for _ in range(W)] for _ in range(H)]

def in_ellipse(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0

def ellipse(cx, cy, rx, ry, color, ymin=-1):
    for y in range(max(0, int(cy - ry - 1)), min(H, int(cy + ry + 2))):
        if y + .5 < ymin: continue
        for x in range(max(0, int(cx - rx - 1)), min(W, int(cx + rx + 2))):
            if in_ellipse(x + .5, y + .5, cx, cy, rx, ry):
                px[y][x] = color

def tri(p1, p2, p3, color):
    def edge(a, b, p):
        return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
    xs = [p1[0], p2[0], p3[0]]; ys = [p1[1], p2[1], p3[1]]
    for y in range(max(0, int(min(ys))), min(H, int(max(ys)) + 1)):
        for x in range(max(0, int(min(xs))), min(W, int(max(xs)) + 1)):
            p = (x + .5, y + .5)
            d1, d2, d3 = edge(p1, p2, p), edge(p2, p3, p), edge(p3, p1, p)
            neg = d1 < 0 or d2 < 0 or d3 < 0
            pos = d1 > 0 or d2 > 0 or d3 > 0
            if not (neg and pos):
                px[y][x] = color

# --- Battle Cats blob cat ---
# tiny pointy ears (ink triangle, white inner)
tri((38, 78), (50, 30), (80, 58), INK)
tri((142, 78), (130, 30), (100, 58), INK)
tri((46, 70), (54, 42), (72, 58), WHITE)
tri((134, 70), (126, 42), (108, 58), WHITE)
# blob body: ink outline then white fill
ellipse(90, 110, 68, 60, INK)
ellipse(90, 110, 61, 53, WHITE)
# small dot eyes, wide apart
ellipse(60, 90, 7, 9, INK)
ellipse(120, 90, 7, 9, INK)
# signature Battle Cat wavy mouth: two rounded bumps across the face
def stroke_quad(p0, p1, p2, r, color):
    steps = 60
    for i in range(steps + 1):
        t = i / steps
        x = (1-t)**2*p0[0] + 2*(1-t)*t*p1[0] + t**2*p2[0]
        y = (1-t)**2*p0[1] + 2*(1-t)*t*p1[1] + t**2*p2[1]
        ellipse(x, y, r, r, color)
stroke_quad((44, 114), (66, 144), (90, 122), 4.5, INK)
stroke_quad((90, 122), (114, 144), (136, 114), 4.5, INK)
# red paw stamp, bottom-right corner
ellipse(150, 156, 13, 10, RED)
ellipse(135, 141, 5.5, 6.5, RED)
ellipse(145, 135, 5.5, 6.5, RED)
ellipse(155, 135, 5.5, 6.5, RED)
ellipse(165, 141, 5.5, 6.5, RED)

def png(path, pixels):
    raw = b''.join(b'\x00' + b''.join(struct.pack('BBB', *p) for p in row) for row in pixels)
    def chunk(tag, data):
        c = tag + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    ihdr = struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)
    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        f.write(chunk(b'IHDR', ihdr))
        f.write(chunk(b'IDAT', zlib.compress(raw, 9)))
        f.write(chunk(b'IEND', b''))

png('apple-touch-icon.png', px)
print('wrote apple-touch-icon.png')
