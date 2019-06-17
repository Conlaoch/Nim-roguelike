import html5_canvas

import type_defs, entity
import calendar

# generic
proc menu(game:Game, header:string, options:seq[string], width:int=100, screen_width:int, screen_height:int, top:int=0, letters:bool=true, centered:bool=true, text="") =
    if options.len > 26: 
        echo("Cannot have a menu with more than 26 options.")
        return

    # calculate height
    let header_height = 2

    let menu_h = int(header_height + 1 + 26)
    let menu_y = int((50 - menu_h) / 2) + top

    var menu_x = 5.0
    if centered:
        menu_x = screen_width/2-width/2;
    
    # background
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(menu_x-2.0, float(menu_y * 10), float(width), float(menu_h * 10));

    game.context.font = "12px Arial";
    game.context.fillStyle = rgb(255, 255, 255);

    # print all the options
    #var y = header_height
    var y = (menu_y + header_height) * 10

    if text != "":
        fillText(game.context, text, menu_x, float(y))

        y += 15 

    var letter_index = ord('a')
    for option_text in options:
        var text = option_text
        if letters:
            text = "(" & chr(letter_index) & ") " & option_text

        fillText(game.context, text, menu_x, float(y));
        # experimental height between lines in px
        y += 10;
        if letters:
            letter_index += 1

# this one has no letters option, and therefore no 26 entries limit
proc menu_colored(game:Game, header:string, options:seq[GameMessage], width:int=100, screen_width:int, screen_height:int, centered=true) =
    # calculate height
    let header_height = 2

    let menu_h = int(header_height + 1 + 26)
    let menu_y = int((50 - menu_h) / 2)

    var menu_x = 5.0
    if centered:
        menu_x = screen_width/2-width/2;
    
    # background
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(menu_x-2.0, float(menu_y * 10), float(width), float(menu_h * 10));

    game.context.font = "12px Arial";
    #game.context.fillStyle = rgb(255, 255, 255);

    # print all the options
    var y = (menu_y + header_height) * 10

    for option in options:
        var text = option[0]
        game.context.fillStyle = rgb(option[1][0], option[1][1], option[1][2]);
        fillText(game.context, text, menu_x, float(y));
        # experimental height between lines in px
        y += 10;


proc text_menu*(game:Game, header:string, text:seq[string], screen_width:int, width:int=100, centered=true) =
    # calculate height
    let header_height = 2

    let menu_h = int(header_height + 1 + 26)
    let menu_y = int((50 - menu_h) / 2)

    var menu_x = 5.0
    if centered:
        menu_x = screen_width/2-width/2;
    
    # background
    game.context.fillStyle = rgb(0,0,0);
    game.context.fillRect(menu_x-2.0, float(menu_y * 10), float(width), float(menu_h * 10));

    game.context.font = "12px Arial";
    game.context.fillStyle = rgb(255, 255, 255);

    var y = (menu_y + header_height) * 10

    #fillText(game.context, text, menu_x, float(y));
    # temporary until newlines/wordwrap work
    for txt in text:
        fillText(game.context, txt, menu_x, float(y));
        # experimental height between lines in px
        y += 10;

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
               "Attack: " & $player.creature.melee, "Dodge: " & $player.creature.dodge,
               "", game.calendar.get_time_date(game.calendar.turn)]
    
    #show money
    for m in player.player.money:
        options.add(m.kind & ": " & $m.amount);
    
    menu(game, header, options, 300, game.canvas.width, game.canvas.height, 10, false)

proc dialogue_menu*(game:Game, header:string, text: string, options: seq[string]) =

    # var text = dialogue.start
    # var options : seq[string]
    # for a in dialogue.answers:
    #     options.add(a.chat)

    menu(game, header, options, 300, game.canvas.width, game.canvas.height, text=text);

proc message_log*(game: Game) =

    # options
    var options: seq[GameMessage];
    for i in game.message_log_index[0]..game.message_log_index[1]:
        if i < game.game_messages.len:
            options.add(game.game_messages[i]);

    menu_colored(game, "MESSAGE LOG", options, 300, game.canvas.width, game.canvas.height);