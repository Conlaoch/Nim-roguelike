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

    //originalcolor(context, color, opacity, image);
    colorImage(context, color, image);
    maskImage(context, image);
    
    context.restore();
  
    return context.canvas;
  }


  function originalcolor(context, color, opacity, image){
    context.fillStyle = color;
    context.globalAlpha = opacity;
    context.fillRect(0, 0, context.canvas.width, context.canvas.height);
    //"source" is the rect, "destination" is the original game canvas AFAICT
    // destination atop - alpha channel = original game canvas, all pixels colored by our rect
    context.globalCompositeOperation = "destination-atop";
    //originally was 1, so none of the original color affected the output
    //the function is usually called with an opacity of 0.5
    context.globalAlpha = opacity;

    //key for the function to work
    context.drawImage(image, 0, 0);

    return context.canvas;
  }

   // based on https://stackoverflow.com/questions/45187291/how-to-change-the-color-of-an-image-in-a-html5-canvas-without-changing-its-patte 
   function colorImage(context, color, image) {
    
    context.globalCompositeOperation = "multiply";

    //key for the function to work
    context.drawImage(image, 0, 0);


    context.fillStyle = color;
    context.fillRect(0, 0, context.canvas.width, context.canvas.height);

    //context.globalCompositeOperation = "color";
    context.globalCompositeOperation = "source-over";
    return context.canvas;
  }

  function maskImage(context, source) {
    context.globalCompositeOperation = "destination-in";
    context.drawImage(source, 0, 0);
    context.globalCompositeOperation = "source-over";
    return context.canvas;
  }