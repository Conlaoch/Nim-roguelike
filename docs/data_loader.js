//https://stackoverflow.com/questions/19706046/how-to-read-an-external-local-json-file-in-javascript?noredirect=1&lq=1
function readTextFile(file, callback) {
    var rawFile = new XMLHttpRequest();
    rawFile.overrideMimeType("application/json");
    rawFile.open("GET", file, true);
    rawFile.onreadystatechange = function() {
        if (rawFile.readyState === 4 && rawFile.status == "200") {
            callback(rawFile.responseText);
        }
    }
    rawFile.send(null);
}

function loadfile(file){
    var data = "";
    readTextFile(file+".json", function(text){
             data = JSON.parse(text);
             console.log(data);
             //return data;
        });
    return data;
}