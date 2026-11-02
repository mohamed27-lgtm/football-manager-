#!/usr/bin/env python3
"""يضيف خط Tajawal إلى pubspec.yaml أثناء البناء (بعد تنزيل ملفاته)."""
from pathlib import Path

p = Path("pubspec.yaml")
s = p.read_text(encoding="utf-8")
if "family: Tajawal" not in s:
    block = """flutter:
  fonts:
    - family: Tajawal
      fonts:
        - asset: assets/fonts/Tajawal-Regular.ttf
          weight: 400
        - asset: assets/fonts/Tajawal-Medium.ttf
          weight: 500
        - asset: assets/fonts/Tajawal-Bold.ttf
          weight: 700
        - asset: assets/fonts/Tajawal-ExtraBold.ttf
          weight: 800
        - asset: assets/fonts/Tajawal-Black.ttf
          weight: 900
  uses-material-design: true"""
    s = s.replace("flutter:\n  uses-material-design: true", block, 1)
    p.write_text(s, encoding="utf-8")
    print("font added")
