# Nim bindings for our JS table_tools.js file
import dom

proc getInventoryKeypad*() : Element {.importc.}
proc createButton*(target:Element, i:int) {.importc.}
proc removeAll*(target:Element) {.importc.}