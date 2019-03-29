//crucial
$( document ).ready(function() {
    $(".key_arrow1").click(function(e) {
        console.log("Clicked a button 1");
    });
    $(".key_arrow2").click(function(e) {
        console.log("Clicked a button 2");
        moveUpNim()
    });
    $(".key_arrow3").click(function(e) {
        console.log("Clicked a button 3");
    });
    $(".key_arrow4").click(function(e) {
        console.log("Clicked a button 4");
        moveLeftNim()
    });
    $(".key_arrow5").click(function(e) {
        console.log("Clicked a button 5");
    });
    $(".key_arrow6").click(function(e) {
        console.log("Clicked a button 6");
        moveRightNim()
    });
    $(".key_arrow7").click(function(e) {
        console.log("Clicked a button 7");
    });
    $(".key_arrow8").click(function(e) {
        console.log("Clicked a button 8");
        moveDownNim()
    });
    $(".key_arrow9").click(function(e) {
        console.log("Clicked a button 9");
    });
 });