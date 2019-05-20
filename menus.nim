import html5_canvas

import type_defs, entity

# generic
proc menu(game:Game, header:string, options:seq[string], width:int, screen_width:int, screen_height:int, top:int=0) =
    if options.len > 26: 
        echo("Cannot have a menu with more than 26 options.")
        return

    # calculate height
    let header_height = 2

    let menu_h = int(header_height + 1 + 26)
    let menu_y = int((50 - menu_h) / 2) + top
    
    game.context.font = "12px Arial";
    game.context.fillStyle = rgb(255, 255, 255);

    # print all the options
    #var y = header_height
    var y = (menu_y + header_height) * 10
    var letter_index = ord('a')
    for option_text in options:
        var text = "(" & chr(letter_index) & ") " & option_text
        fillText(game.context, text, 5.0, float(y));
        # experimental height between lines in px
        y += 10;
        letter_index += 1

# specific
proc inventory_menu*(game:Game, header:string, inventory:Inventory, inventory_width:int, screen_width:int, screen_height:int) =
    var options: seq[string]
    # show a menu with each item of the inventory as an option
    if inventory.items.len == 0:
        options = @["Inventory is empty."]
    else:
        #options = [item.owner.name for item in inventory.items]
        for item in inventory.items:
            options.add(item.owner.display_name);

    menu(game, header, options, inventory_width, screen_width, screen_height)

proc character_sheet_menu*(game:Game, header:string, player:Entity) =
    var options = @["STR: " & $player.creature.base_str, "DEX: " & $player.creature.base_dex,
               "CON: " & $player.creature.base_con, "INT: " & $player.creature.base_int,
               "WIS: " & $player.creature.base_wis, "CHA: " & $player.creature.base_cha,
               "Attack: " & $player.creature.melee, "Dodge: " & $player.creature.dodge]
    
    menu(game, header, options, 50, game.canvas.width, game.canvas.height, 10)
