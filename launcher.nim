import webview
import os

let dir = os.getCurrentDir()

##echo(dir)

## to fit 800x600 canvas and keypad without scrollbars
## we use file:// protocol to open a local site
open("Minimal webview example", "file:///"&dir&"/docs/index.html", 850, 850, true)