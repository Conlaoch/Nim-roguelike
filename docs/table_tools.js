

function createButton(target, i){
    //yet another thing that Nim can't do itself
    var cell = target.insertCell();
    //iterate over char codes to get the letters
    var val = String.fromCharCode(97 + i);
    var btn = document.createElement("input");
    btn.type = "button";
    btn.value = val;
    btn.setAttribute('onclick', "inventorySelectNim(this.value.charCodeAt(0)-97)");
    cell.appendChild(btn);
}

function getInventoryKeypad(){
    keypad = document.getElementById("inventory_keypad")
    //Nim cannot use rows or other special table props which make working with them easier
    target = keypad.childNodes[1].rows[1];
    return target;
}

function removeAll(target) {
    for (cell of target.cells){
        //console.log(cell.cellIndex);
        target.deleteCell(cell.cellIndex);
    }

}