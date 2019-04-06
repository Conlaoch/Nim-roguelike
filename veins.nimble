# Package

version       = "0.0.1"
author        = "Zireael"
description   = "A simple web roguelike, built to learn Nim."
license       = "MIT"

# Dependencies

requires "nim >= 0.19.0"
requires "https://github.com/define-private-public/HTML5-Canvas-Nim"

# for launcher
requires "https://github.com/oskca/webview"

task launch, "builds the app and runs it":
    exec "nim c launcher.nim"