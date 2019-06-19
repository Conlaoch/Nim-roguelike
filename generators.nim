import data_loader
import jsffi # to be able to do stuff with the data we loaded from JS side
import tables
import type_defs
import entity

# globals
var items_data*: JsObject;
var monster_data*: JsObject;
var dialogue_data*: JsObject;

proc loadfiles*() =
    data_loader.load_files(@[cstring("data/items"), cstring("data/test"), cstring("data/dialogue")]);


    # test
    #data_loader.loadfile("/data/items");

# helper
# 1 gp = 20 sp
proc calculate_price(cost: JsObject) : int =
    var price = 0
    
    #echo $cost
    for k in cost.keys:
        echo $k & " : " & $to(cost[k], int);

    if cost.hasOwnProperty("silver"):
        price += to(cost["silver"], int)
    if cost.hasOwnProperty("gold"):
        price += to(cost["gold"], int)*20

    echo("Calculated price is: " & $price & " sp")

    return price

proc generateItem*(id:string, x: int, y:int) : Entity =
    echo "Generate item with id: " & $id

    if isNil(items_data[id]):
        echo("No item with id " & $id);
        return nil

    else:
        var item_name = to(items_data[id]["name"], cstring);
        echo $item_name;

        var item_image = to(items_data[id]["image"], int);
        echo $item_image;
        
        var en_it = Entity(position:(x,y), image:item_image, name: $item_name);
        # item component
        var it = Item(owner:en_it);
        en_it.item = it;

        var item_type = to(items_data[id]["type"], cstring);
        if items_data[id].hasOwnProperty("cost"):
            var cost_data : JsObject
            it.price = calculate_price(items_data[id]["cost"]);

        # optional parameters depending on type
        if item_type == "weapon":
            var num_dice = to(items_data[id]["damage_number"], int);
            var damage_dice = to(items_data[id]["damage_dice"], int);
            var item_slot = to(items_data[id]["slot"], cstring);

            # equipment component
            var eq = Equipment(owner:en_it, slot: $item_slot, num_dice: num_dice, damage_dice:damage_dice);
            en_it.equipment = eq;
        
        if item_type == "armor":
            var def_bonus = to(items_data[id]["combat_armor"], int);
            var item_slot = to(items_data[id]["slot"], cstring);
            # equipment component
            var eq = Equipment(owner:en_it, slot: $item_slot, defense_bonus: def_bonus);
            en_it.equipment = eq;

        echo("Spawned item at " & $en_it.position);
        return en_it;

proc generateMonster*(id: string, x,y:int) : Entity =
    echo "Generate monster with id: " & $id

    if isNil(monster_data[id]):
        echo("No monster with id " & $id);
        return nil

    else:
        var mon_name = to(monster_data[id]["name"], cstring)
        var item_image = to(monster_data[id]["image"], int);
        echo $item_image;
        
        var mon = Entity(position:(x,y), image:item_image, name: $mon_name);

        var mon_hp = to(monster_data[id]["hit_points"], int)
        #var mon_dam_num = to(monster_data[id]["damage_number"], int)
        #var mon_dam_dice = to(monster_data[id]["damage_dice"], int)
        var fact = to(monster_data[id]["faction"], cstring)

        var langs : seq[string]
        if monster_data[id].hasOwnProperty("languages"):
            for k in monster_data[id]["languages"].keys:
                var lg = to(monster_data[id]["languages"][k], cstring)
                langs.add($lg)


        var mon_text = cstring("")
        if monster_data[id].hasOwnProperty("text"):
            echo $id & " has text entry"
            mon_text = to(monster_data[id]["text"], cstring)
        
        var mon_chat_id = cstring("")
        var mon_chat: Dialogue
        if monster_data[id].hasOwnProperty("chat"):
            #echo $id & " has chat entry"
            var mon_chat_data: JsObject
            mon_chat_id = to(monster_data[id]["chat"], cstring)
            mon_chat_data = dialogue_data[mon_chat_id]
            # parse the chat itself
            var chat = to(mon_chat_data["chat"], cstring)
            #echo $chat
            var answers : seq[DialogueReply]

            for k in mon_chat_data["answer"].keys:
                var entry = ($to(mon_chat_data["answer"][k]["chat"], cstring), $to(mon_chat_data["answer"][k]["reply"], cstring))
                answers.add(entry);
            #echo $answers

            # load any further entries
            var texts: seq[DialogueText]
            for k in mon_chat_data.keys:
                if k != cstring("chat") and k != cstring("answer"):
                    #echo "entry: " & $k
                    # only those entries that match a reply tag
                    for e in answers:
                        if k == cstring(e.reply):
                            #echo "entry " & $k & " fits reply " & $e.reply
                            texts.add(($k, $to(mon_chat_data[k], cstring)));
            
            #echo $texts

            mon_chat = Dialogue(start: $chat, answers:answers, texts:texts);

        # Inventory
        var inv = Inventory(owner:mon);
        mon.inventory = inv;

        # equip equipment
        var mon_equip_id = cstring("")
        if monster_data[id].hasOwnProperty("equipment"):
            for e_id in monster_data[id]["equipment"].keys:
                mon_equip_id = to(monster_data[id]["equipment"][e_id], cstring);
                echo "Equip id: " & $mon_equip_id;
                var mon_equip = generateItem($mon_equip_id, x,y)
                mon_equip.item.add_to_inven(mon); 

        # creature component
        var creat = newCreature(owner=mon, hp=mon_hp, defense=30, attack=20, 
        faction= $fact, text= $mon_text, chat= mon_chat, languages= langs);
        mon.creature = creat;
        # AI component
        var AI_comp = AI(owner:mon);
        mon.ai = AI_comp;
        echo("Spawned monster at " & $mon.position);
        return mon;

proc getData*() : Table[cstring, JSObject] =
    var data : JsObject;
    data = data_loader.get_loaded();

    # convert to a proper table
    var dat = initTable[cstring, JsObject](32);
    for k,v in data:
        # duplicates shouldn't be an issue
        dat.add(to(data[k][0], cstring), data[k][1])

    return dat;

# the callback on loading all data files was moved to main.nim


