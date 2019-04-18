import entity

proc heal*(item:Item, user:Entity) =
    echo "Heal..."
    if user.creature.hp < user.creature.max_hp:
        var amount = min(user.creature.max_hp-user.creature.hp, 5);
        user.creature.hp += amount;
        user.inventory.items.delete(user.inventory.items.find(item));