# roguelike-tutorial-Nim
Web (desktop&amp;mobile) version of Veins, using HTML + CSS + JS + Nim

## Why Nim?

Nim's syntax is very similar to my go-to, that is Python. It compiles to JS, and for cases where you can't get something working with it alone, it easily interops with JS (so you can write a tiny toy library for anything you need, and/or use existing JS libraries). It also has a neat way of creating OOP classes, so it allows me to avoid the JS Prototype syntax that I have an irrational hatred of :)

## Libraries?

We are using jQuery for binding the JS to the HTML buttons which provide an alternative way of interacting with the game for e.g. mobile browser users (or if you simply don't want to use the keyboard). Other than that, no big name JS libraries are used. On the Nim side, the only library we need is the HTML Canvas bindings.

## Tutorial

I am following the Python 3 tutorial http://rogueliketutorials.com/tutorials/tcod/. It is 90% the same as the venerable Python 2 Roguebasin tutorial that I already followed twice, with Python 2 and Haxe.

## Notes

### Part 1

Setting up: for Windows, download Nim from their site: https://nim-lang.org/install.html
On Windows, it's quicker to just grab the zip. On Linux, use curl (Nim development is so fast that the version in package manager is very likely very much out of date)

To be able to use the HTML Canvas API from Nim, type nimble install html5_canvas in your console/terminal - this grabs the only Nim library we need that's not in the standard lib.

Instead of tacking the graphics on as a bonus, we are starting with them right away. They are isometric, check out the math involved at https://gamedevelopment.tutsplus.com/tutorials/creating-isometric-worlds-primer-for-game-developers-updated--cms-28392?_ga=2.20302904.14685188.1530446365-1060515045.1508064120

I couldn't get Image.onload to work in Nim due to closure/nimcall distinction, so I made a tiny JS script and Nim bindings for it. Check out docs/resources.js and resources.nim for details.

### Part 3

The map is intentionally very simple (a large room surrounded by walls) but it is enough to show procedurality (with a single line change, I could make the floor sand or the walls different). BSP map is not a requirement, and showing it off properly would require a camera/viewport system due to tile sizes, which is outside the scope of the tutorial.

### Part 4

The FOV is adapted from a Godot tutorial (you can see some Python-isms commented out for comparison's sake). The algorithm is not described, but the behavior fits recursive shadowcasting. It's therefore not perfectly permissive but it is easy enough to implement and understand.

This part also required tinting images (to avoid doing many versions of the same tile differing only in shading). It was implemented in JS and exposed to Nim.

### Part 5

The RNG used is, as far as I know, only used in the web world. It's called Alea and used under the hood by e.g. rot.js. I moved some functions around to make it easier to write Nim bindings.

I did not use rot.js itself due to its size - jQuery alone is enough to increase download size.

For checking whether the entity blocks, I check for the presence of a Creature component instead of a blocks flag - this is a deliberate deviation from the tutorial for ease of use because the Creature is going to be used a lot in part 6 anyway.

### Part 6

For pathfinding, I used a preexisting JS A* implementation (too small to be really called a library). I had to edit it, however, as it assumed the map is represented as a 2D array and we use a 1D array.

Message log display uses the same technique as the Python tutorial, that is "list slicing". It is not available in Nim out-of-the-box, I had to implement it myself (see seq_tools.nim).

Monster and player death was the biggest pain point so far and where our logic differs the most from Python, which just used requisite functions as parameters. Instead, we add a "dead" flag to entity and then fire the death functions from the main loop (we cannot call anything in game_class.nim from entity.nim because this means recursive module definitions, and those are not allowed in Nim). The "dead" entities are removed in a separate loop to avoid "modifying while iterating" error.

### Part 7

We already handled message log display in part 6 because the browser console was getting clogged up with all the logs.

### Part 8

We are using Canvas API for displaying the inventory, even though it could have been done in HTML by manipulating DOM. That would be a nice thought exercise for the future.

Unlike my previous attempts at this tutorial, this time we are using the separate game states for GUI - I believe it does solve some of the input/redrawing niggles that only become obvious many months later.

The main problem here was not the game logic or drawing itself, but the creation and display of a separate HTML button panel for when the inventory/drop menu is open. Nim has a built in DOM manipulation library, but writing a small JS script (with accompanying Nim bindings) made it easier due to the special properties <table> objects have such as rows().
