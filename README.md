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

```javascript
function mouseDragged() {
  if (drawing && touches.length < 2) {
    path.push(createVector(mouseX, mouseY));
  }
}
```

We also add a button outside our canvas using p5.dom's ```createButton``` to clear the current path.

#### Syncing the paths

Server time! The Node-Express server is set up with two routes. The default ```/``` route serves a version of the map that shows only your own path. Additionally, the ```/all``` route displays real-time updates of all paths, from the moment it was loaded onwards. Using socket.io, we can emit events and listen for them.

Each instance of the map is assigned a unique id (thanks socket.io), as well as a random color to differentiate between participants.

Every time a path adds a point, it emits a ```'point'``` event that relays its ```id```, ```color```, as well as ```x``` and ```y``` coordinates. The coordinates are normalized to account for different screen sizes. The event and its data is relayed from the server to all clients. ```/``` clients ignore the event, while ```/all``` clients listen to it and update their map accordingly (they ignore events tagged with their own id).

Pressing the clear button clears the path locally, and it sends a ```'clear'``` event with the ```id``` of the socket to clear the path in remote clients, as well.

#### Feedback time!

- Offline - internet access might not be a given in all venues.
- Paths will be discrete, from country to country, rather than continuous user-defined paths.
- Paths will be defined and then submitted, rather than drawn in real time.
- User interaction:
  - Single drag to move map
  - Double tap to select country
  - Submit button to send finished journey
  - Undo/Clear button to fix mistakes
- Combined map will be a heatmap + paths: countries light up more as more people select them in their journeys, and travels are traced and animated after submission.
- Ideally, design allows for the addition of granularity (states and cities) at a later date

### V.2

#### Getting map data

Offline app means no Google Maps; no Google Maps means goodbye to all that nifty map data. If the app is to become more granular later, it will need some geographical data to store names and coordinates easily. So ```map.gif``` won't cut it.

The good news: Natural Earth has a huge, open-access dataset on all things Earth. So we got country, state/province, and city data!

The bad news: the data is in some weird shapefile format(s). Gotta convert to SVG.

Luckily, the fine folks at [Mapshaper](mapshaper.org) feel our pain and provide a free tool to convert our map data! YAY! However, getting metadata to stick with the SVG (like country names and whatnot) doesn't happen by default. When exporting, we must specify in the command line options what to keep and how. To bind the country name to the path's id, for instance:

```
id-field=NAME
```

Figuring out what data comes with the shapefile and how it is labeled involves looking through the ```.dbf``` file included (it's some ancient database format). [DBFOpener](dbfopener.com) allows us to inspect the file in a readable format in our browser.

#### From data to experience
