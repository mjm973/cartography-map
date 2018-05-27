## Cartography Web Map

### V.1

#### Making the Map

The map is rendered using p5.js, witht the p5.dom extension to easily integrate DOM manipulation. The map is centered in the screen using the following styling:

```
display: flex;
height: 100%;
width: 100%;
align-items: center;
align-content: center;
justify-content: center;
```

We ```preload``` the map onto p5, and then create a canvas that keeps the map's aspect ratio but takes up 90% of the screen's vertical space.

#### Drawing the paths

p5.js's built-in ```mousePressed```, ```mosueDragged```, and ```mouseReleased``` also capture the equivalent touch-based events if they are not defined, so we use the mouse-based events.

To generate a path, we push p5.Vector entries onto an array. ```mousePressed``` registers the start of a drawing gesture (and adds a single pont if the path is empty), ```mouseDragged``` adds additional points as the mosue/touch is dragged along, and ```mouseReleased``` ends the gesture. The path needn't be drawn in a single stroke: ```mouseDragged``` will resume drawing on subsequent strokes.

Zooming is handled by the browser's default behavior. However, for the experience to be smooth we have to disable drawing when a zoom gesture is initiated: we make sure we only add points if we have less than two active touches.

```
function mouseDragged() {
  if (drawing && touches.length < 2) {
    path.push(createVector(mouseX, mouseY));
  }
}
```

We also add a button outside our canvas using p5.dom's ```createButton``` to clear the current path, as well as one to submit it.
