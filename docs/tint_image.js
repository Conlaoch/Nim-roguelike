// based on https://github.com/matmartinez/tinto

let context; // cache

function tintImage(image, color, opacity = 0.5) {
    if (!context) {
      //the string here absolutely needs to be "canvas", not "canvas-temp" or any such
      //therefore the canvas game element cannot have an id of "canvas"...
      var canvas = document.createElement('canvas');
      context = canvas.getContext("2d");
      canvas.width = image.width;
      canvas.height = image.height;
    } else {
      context.canvas.width = image.width;
      context.canvas.height = image.height;
    }
  
    context.save();
    context.fillStyle = color;
    context.globalAlpha = opacity;
    context.fillRect(0, 0, context.canvas.width, context.canvas.height);
    context.globalCompositeOperation = "destination-atop";
    context.globalAlpha = 1;
    context.drawImage(image, 0, 0);
    context.restore();
  
    return context.canvas;
  }