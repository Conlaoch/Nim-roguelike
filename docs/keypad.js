//crucial
$( document ).ready(function() {
    //hide inventory keypad
    $("#inventory_keypad").hide();
    //hide targeting keypad
    $("#targeting_keypad").hide();
    
    $(".key_arrow1").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 1");
        moveLeftUpNim()
    });
    $(".key_arrow2").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 2");
        moveUpNim()
    });
    $(".key_arrow3").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 3");
        moveRightUpNim()
    });
    $(".key_arrow4").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 4");
        moveLeftNim()
    });
    $(".key_arrow5").click(function(e) {
        console.log("Clicked a button 5");
    });
    $(".key_arrow6").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 6");
        moveRightNim()
    });
    $(".key_arrow7").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 7");
        moveLeftDownNim()
    });
    $(".key_arrow8").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 8");
        moveDownNim()
    });
    $(".key_arrow9").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 9");
        moveRightDownNim()
    });
    $(".key_get").click(function(e) {
        console.log($(this));
        pickupNim()
    });
    $(".key_inv").click(function(e) {
        showInventoryNim()
    });
    $(".key_drop").click(function(e) {
        showDropNim()
    });
    $(".key_esc").click(function(e){
        quitInventoryNim()
    })
    //targeting keys
    $(".key_tg_arrow1").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 1");
        moveTargetNim(-1,-1)
    });
    $(".key_tg_arrow2").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 2");
        moveTargetNim(0,-1);
    });
    $(".key_tg_arrow3").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 3");
        moveTargetNim(1,-1)
    });
    $(".key_tg_arrow4").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 4");
        moveTargetNim(-1,0);
    });
    $(".key_tg_arrow6").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 6");
        moveTargetNim(1,0);
    });
    $(".key_tg_arrow7").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 7");
        moveTargetNim(-1,1)
    });
    $(".key_tg_arrow8").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 8");
        moveTargetNim(0,1)
    });
    $(".key_tg_arrow9").click(function(e) {
        //console.log($(this));
        console.log("Clicked a button 9");
        moveTargetNim(1,1)
    });
    $(".key_tg_esc").click(function(e) {
        quitTargetingNim();
    });
    $(".key_tg_enter").click(function(e){
        confirmTargetNim();
    });
 });