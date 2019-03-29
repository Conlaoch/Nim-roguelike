import webview
import os

let dir = os.getCurrentDir()

##echo(dir)

## to fit 800x600 canvas without scrollbars
## we use file:// protocol to open a local site
open("Minimal webview example", "file:///"&dir&"/index.html", 850, 650, true)