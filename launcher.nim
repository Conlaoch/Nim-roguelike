import webview
import os

let dir = os.getCurrentDir()

##echo(dir)

## to fit 800x600 canvas and keypad without scrollbars
## we serve the site because otherwise we can't request data files
## this function from server module is blocking, we can't really do anything while this runs
##defaultServe()

## YOU NEED TO RUN ./server first (e.g. from a terminal) (or python3 -m http.serve if you have python)
open("Minimal webview example", "http://localhost:8000", 850, 850, true)
#open("Minimal webview example", "file:///"&dir&"/docs/index.html", 850, 850, true)