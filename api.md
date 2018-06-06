## Cartography Map API

The map application consists in three components:

- A client side map: this is where users input their journeys and submit them
- A Node-Express server: it serves the map website, recieves and stores journey data from users, and relays this data to the display app
- A display application (built using Processing): it receives data from the server, displays it on a map, and communicates via Syphon with Isadora to project the map.

Below is documentation on the interfaces available for each of the components.

### Client Map

The client side shows an map of the world (Mercator projection) rendered as an SVG image. Users can use the browser's built-in gesture inputs to navigate: single drag to scroll, pinch to zoom, etc. Additionally, users can double-tap to select countries and add them to their journey.

The journey is displayed in a list next to the map. There are also two buttons: ```Undo```, which clears the last element in the list, and ```Submit```, which sends the journey data to the server. Users can also tap on a particular list element to remove it from their journey.

### Server

The server handles requests from the audience clients, and keeps track of the journeys they input. It keeps a ```journeys``` array with the master log of all journeys.

Currently, the server supports the following routes:

| Route           | Method | Use                                                                     |
|:---------------:|:------:|-------------------------------------------------------------------------|
| `'/'`           |`GET`   | Serves the client-side map for audience users                           |
| `'/api/submit'` |`POST`  | Receives journey data sent by users in JSON format                      |
| `'/api/sync'`   |`GET`   | Used by the Display App to retrieve the full journey data               |
| `'/api/update'` |`POST`  | Used by the Display App to retrieve only new journey data (in progress) |
| `'/api/clear'`  |`GET`   | Allows clearing the `journeys` array if needed, and redirects to `'/'`  |
| `'/*'`          |`GET`   | Catch-all, redirects any other request to `'/'`                         |

### Display Application

The display application runs as a Processing sketch. It uses the HTTP Requests for Processing library to interface with the server and fetch the journey data. The app loads the same SVG file used in the client web app into a `PShape` object and splits it for further manipulation.

- NOTE: There seems to be a bug with Processing's P2D OpenGL rendering engine when drawing the country strokes. As it stands, it will cause the application to take a while to start, but should run smoothly afterwards.

Here are the global parameters:

| Name                      | Type                | Use                                                                          |
|:-------------------------:|:-------------------:|------------------------------------------------------------------------------|
| `syncTime`                | `float`             | Approximate time in seconds between sync requests to server                  |
| `pathR`, `pathG`, `pathB` | `int`               | Define color for travel paths                                                |
| `maxTally`                | `int`               | Number of visits at which a country will reach its darkest/maximum color     |
| `minR`, `minG`, `minB`    | `int`               | Define color for countries with a single visit (lightest/minimum)            |
| `maxR`, `maxG`, `maxB`    | `int`               | Define color for countries with `maxTally` or more visits (darkest/maximum)  |
| `bgR`, `bgG`, `bgB`       | `int`               | Define background color                                                      |
| `stR`, `stG`, `stB`       | `int`               | Define country stroke color                                                  |
| `fromBg`                  | `boolean`           | If `true`, min color defaults to background color                            |
| `scaleY`                  | `float`             | Scales the map vertically                                                    |
| `anipationPathMode`       | `AnimationPathMode` | Defines path drawing method. Can be `LINE`, `ARC` or `SHALLOW_ARC`           |
| `animationPathTime`       | `int`               | Time (in milliseconds) it takes to trace a bath between two countries        |
| `animationLoop`           | `boolean`           | Whether to loop the travel animations or not                                 |
| `animationShowMarker`     | `boolean`           | Whether to show a marker at the current point of travel                      |
| `animationFadeBorders`    | `float`             | Fades from no borders (0) to solid borders (1). Exposed for manual override. |
| `animationFadeStep`       | `float`             | Defines the speed of the border fade, per frame                              |
| `animationFadeIn`         | `boolean`           | `true` to fade borders in; `false` to fade them out                          |
| `animationRadiusFactor`   | `float`             | Determines shallowness of `SHALLOW_ARC`. Minimum is 1 (semicircle)           |
| `animationGradualColor`   | `boolean`           | Do we color countries as we visit them (in "real-time")?                     |
