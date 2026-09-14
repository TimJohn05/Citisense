#!/usr/bin/env python3
"""Fetch OSM tiles for the Calamba, Laguna area into Flutter assets for
offline use (tool run once; tiles committed as assets).

Bounds cover the app demo area (Calamba center 14.1956, 121.1469 and
officer demo route at 14.2095, 121.1525 are inside).

Maps to tile.openstreetmap.org / {z}/{x}/{y}.png. Runs single-threaded and
pauses between requests to stay within OSM tile usage policy for a small,
educational, non-commercial region fetch.
"""

import math
import os
import time
import urllib.request

LAT_MIN, LAT_MAX = 14.15, 14.25
LON_MIN, LON_MAX = 121.10, 121.20
ZOOMS = range(13, 17)
OUT = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "assets", "tiles",
)
UA = "CitiSense/1.0 (academic Spring 2026; contact none)"


def xy(lat, lon, z):
    n = 1 << z
    x = (lon + 180.0) / 360.0 * n
    t = math.tan(math.radians(lat))
    y = (1.0 - math.asinh(t) / math.pi) / 2.0 * n
    return x, y


def main():
    for z in ZOOMS:
        x0, y0 = xy(LAT_MAX, LON_MIN, z)
        x1, y1 = xy(LAT_MIN, LON_MAX, z)
        xa, xb = math.floor(x0), math.floor(x1)
        ya, yb = math.floor(y0), math.floor(y1)
        for x in range(xa, xb + 1):
            for y in range(ya, yb + 1):
                target = os.path.join(OUT, str(z), str(x), f"{y}.png")
                if os.path.exists(target) and os.path.getsize(target) > 0:
                    continue
                os.makedirs(os.path.dirname(target), exist_ok=True)
                url = f"https://tile.openstreetmap.org/{z}/{x}/{y}.png"
                req = urllib.request.Request(url, headers={"User-Agent": UA})
                with urllib.request.urlopen(req, timeout=30) as resp, open(
                    target, "wb"
                ) as fh:
                    fh.write(resp.read())
                time.sleep(0.08)
                print(f"z{z} {x}/{y}")


if __name__ == "__main__":
    main()