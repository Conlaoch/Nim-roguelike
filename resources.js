// simple loader based on  https://github.com/jlongster/canvas-game-bootstrap
// & https://codepen.io/dipscom/pen/bdyEZY

initLoader = function(window){
    //it's 2019, use a proper map! (ES 6 feature [!])
    resourceCache = new Map();
    readyCallbacks = [];

    window.resources = {
        onReady: onReady,
    }
    return window.resources
}

 // Load an array of image urls
 function load(urlOrArr) {
    count = urlOrArr.length;
    //urlOrArr.forEach(function(url) {
    for (n =0;n < count; n++){
        url = urlOrArr[n];
        console.log("Loading..." + url);
        _load(url, count);
    }
}

function _load(url, count) {
    //if(resourceCache[url]) {
    if (resourceCache.has(url)){
        return resourceCache.get(url);
    }
    else {
        var img = new Image();
        img.onload = function() {
            console.log("onload");
            resourceCache.set(url, img);
            //resourceCache[url] = img;
            
            countReady(count);
        };
        resourceCache[url] = false;
        //resourceCache.set(url, false);
        img.src = url;
    }
}

function get(url) {
    console.log("Getting... " + url);
    if (resourceCache.has(url)){
        console.log("We have " + resourceCache.get(url));
    }
    //return resourceCache[url];
    return resourceCache.get(url)
}

function countReady(count) {
    // Once loaded
    // Subtract one from the count of images loading
    count--;
    // When the count reaches zero
    if( count === 0 ) {
      // All images have loaded
        onReady();
    }
  }


function onReady() {
    console.log("JS onready");
    // call Nim function
    onReadyNim()

}
