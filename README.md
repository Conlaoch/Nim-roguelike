# roguelike-tutorial-Nim
Web (desktop&amp;mobile) version of Veins, using HTML + CSS + JS + Nim

## Why Nim?

Nim's syntax is very similar to my go-to, that is Python. It compiles to JS, and for cases where you can't get something working with it alone, it easily interops with JS (so you can write a tiny toy library for anything you need, and/or use existing JS libraries). It also has a neat way of creating OOP classes, so it allows me to avoid the JS Prototype syntax that I have an irrational hatred of :)

## Libraries?

We are using jQuery for binding the JS to the HTML buttons which provide an alternative way of interacting with the game for e.g. mobile browser users (or if you simply don't want to use the keyboard). Other than that, no big name JS libraries are used. On the Nim side, the only library we need is the HTML Canvas bindings.

## Tutorial

I am following the Python 3 tutorial http://rogueliketutorials.com/tutorials/tcod/. It is 90% the same as the venerable Python 2 Roguebasin tutorial that I already followed twice, with Python 2 and Haxe.

## Notes

See TUTORIAL_NOTES.md file for details.