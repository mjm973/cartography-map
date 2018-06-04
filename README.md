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
With this, our SVG map is generated and each country polygon has the country's name as its id.

Figuring out what data comes with the shapefile and how it is labeled involves looking through the ```.dbf``` file included (it's some ancient database format). [DBFOpener](dbfopener.com) allows us to inspect the file in a readable format in our browser.

#### From data to experience

Once the map has country names attached to it, we can start tracking a journey. Using an event, we can determine which country was selected, apply a style to it, and make a list of our travels. The country is appended to two lists: a ```journey``` array that will hold all the data for submission, and a list that is rendered in the HTML with the selected countries in the order they were visited.

- ```addCountry``` adds the selected country to the end of our lists. It checks that we aren't adding the same country twice in a row, creates a list element for the user, and adds the entry to the ```journey``` array.
- ```popCountry``` is the opposite: it pops the last country from ```journey``` and removes it from the list. It also checks if ```journey``` still includes the removed country, and deselects the country if it doesn't.
- ```remCountry``` removes countries at arbitrary positions. It leaves a ```null``` entry in ```journey``` so that we don't mess up the indexing and we can remove as many countries as we want this way (we'll clean up the array on submission). Of course, it also checks for deselection.

To implement this, we have three main points of interaction:

- A double tap gesture to select countries in the map using ```addCountry```. To do so, we set a timeout after the first tap and we check that the second tap comes alone (i.e. we aren't pinching the screen):

  ```javascript
  country.addEventListener('touchstart', (e) => {
    // New taps reset our timeout, even when it's multiple fingers
    if (!tap || e.touches.length > 1) {
      tap = setTimeout(() => {
        tap = null;
      }, 300);
    } else {
      // If the second tap comes from a single finger, we clear the timer and add the country
      clearTimeout(tap);
      tap = null;

      e.preventDefault();
      addCountry(country);
    }
  });
  ```

- An ```Undo``` button. This just fires the ```popCountry``` function.
- An event listener on the country list elements. For now, clicking on the list element removes it, but this can be easily adapted to a remove button or any other event-based input. The event fires ```remCountry``` on the country we want to remove.

#### More Data: Tags and Flags

Natural Earth unfortunately doesn't seem to have anything but map data, so I had to find another database to work with in tandem. Turns out cristiroma on GitHub had a very handy [dataset](https://github.com/cristiroma/countries) which solved two issues: linking countries to flags and determining "canonical" coordinates for each country.

The data set wasn't perfect, though, so I had to edit some of the entries manually for a near-perfect match. Using JavaScript's ```Array.includes```, ```Array.map``` and ```Array.filter``` I could quickly determine the mismatching countries to edit. In the end, only 5 regions from Natural Earth's map data are left without a flag.

With the data ready, adding it to the existing app was straightforward.

We use the same iteration that set up the country paths' ids in place. For the tags, we create new ```div```s and append then to the document with the country name inside. We make sure we give them a ```hidden``` class so they are invisible. Then, in the country events, we remove their class on hover/touch, and add it again once the hover/touch is done. We also update their inline style so they pop up where we touched.

For the flags, we simply pass in the flag filename to the event binder function ```addCountryEvents```. That way, when we add a country to our path we can make sure the appended entry in the list includes an ```img``` tag that loads up the proper country flag.

#### Linking things together

With this new version of the map, the server's routes and functions had to change. The server now exposes an API that allows the map clients to submit their journeys via `POST` request. The `'/api/submit'` route takes JSON data from the client, which waits for a successful response before clearing its journey in the client map. The API also allows the Display Application to fetch the full journey data to display it on the screen/projection via the `'/api/sync'` route. A special route, `'/api/clear'` would allow the crew to reset the journey data without restarting the server, if the need should arise.

The data is stored as a 2D array of JavaScript objects. Each journey is an array, and each country in that array is an object with `name`, `lon` and `lat` fields (both normalized for easy use!). Submissions simply push new entries onto the array, and sync requests prompt the server to send the full journey data to the Display application.

#### Mapping the full picture

To make the Display App, I chose to work on Processing. Processing supports Syphon to pipe the graphics onto Isadora, SVG loading and manipulation, and has a library for straightforward HTTP requests.

The app loads the same SVG map as the web client onto a `PShape` object. However, to style the individual countries it was necessary to use the shape's `getChild` method to access each country's path and name (found as `PShape.name`, it happens to pull the element's `id` field). With that set, we could now render and style countries individually, getting us closer to the heatmap half of the app.

To fetch the data, we used the HTTP Requests for Processing library to make and configure a `GetRequest` and finally retrieve our data. Processing's `parseJSONArray` function (not `parseJSONObject`, because we are dealing with arrays here!) returns our data as a `JSONArray` object, which we can then iterate over to count the number of times a country has been visited and save it into a `HashMap`. This makes querying the values by country really easy when we color the map. In doing so, we wrap each country `PShape` inside a `Country` object to streamline its rendering and tallying.

#### Tracing the paths

Animation time! To animate the travels, we needed some kind of timer and variables to keep track of the animation's state. Processing's `millis` would be our de-facto timer: by keeping track of `animationLastTick` and defining an `animationPathTime`, we can set a timer to increase `animationIndex` every, say, 1 second and thus move from one path segment to the next. The idea is that every "tick", we draw the path from one country to the next, and we keep going until reaching the end of the journey. Thansk to our normalized `lon` and `lat` fields from our client submissions, intermolating and drawing our journeys in the map becomes super simple! Just take the normalized `lon` and `lat`, multiply by the map's `width` and `height` and done! (All hail normalization).

Making the paths (not only the points) animated was straightforward from there, as the same point can be reused to draw a line from the last country to the curent point. Straight lines are not the most aesthetic paths we can trace, so we added an `AnimationPathMode` `enum` to switch between drawing modes. `LINE` would draw straight lines, as usual, while `ARC` would draw semicircles between countries. Drawing the arcs involved a bit more math (calculating centers and angles), but relies in essentially the same principle.

Another thing to animate was the borders btween countries: these should fade in at some point in the performance. Now that we had individual control over country shapes, adding a stroke was trivial. Using an `animationFadeBorders` global to keep track of the fade and `animationFadeStep` to control the speed of the fade, the animation became a simple linear interpolation controlled by an `animationFadeIn` boolean. `animationFadeBorders` should be exposed, though, to allow for manual override.
