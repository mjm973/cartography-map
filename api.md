# Cartography Map API

The map application consists in three components:

- A client side map: this is where users input their journeys and submit them
- A Node-Express server: it serves the map website, recieves and stores journey data from users, and relays this data to the display app
- A display application (built using Processing 3.3.7): it receives data from the server, displays it on a map, and communicates via Syphon with Isadora to project the map.

## Setup

### Server + Client

To get the Map applications on your computer, download this repository or clone it from the command line:

```bash
$ git clone https://github.com/mjm973/cartography-map.git
```

Then, make sure Node is installed on the computer running the map. If not, install node from their [website](https://nodejs.org), or using Homebrew from the terminal:

```bash
$ brew install node
```

Next, navigate to repository's folder in the command line to install the Node dependencies. Once you are there, run

```bash
$ npm install
```

This should install everything needed to run the server. With that ready, you can run the server with

```bash
$ node server.js
```

Opening a browser and navigating to `http://localhost` should now display the Map Client!

### Display Application

Ideally, you should have an exacutable version of the Display App that you can just run and launch anytime. If for whatever reason (tweaking variables, further revision, the executable lived in a USB Drive which got lost) you need to re-build it or launch it from Processing, keep reading. Else, you can skip to *Api Use*.

Okay, so we need to re-build or run in Processing. Open the main file in Processing (`map_display.pde`). This should also open all other relevant files in different tabs. Yay!

First things first, we need to make sure Syphon is enabled (otherwise, we can't send the image data to Isadora). Find the following lines of code and make sure they are uncommented (i.e. they don't start with `//`):

```java
// In map_display.pde: Lines 7 and 110

...
SyphonServer server; // Uncomment on Mac to enable Syphon
...
server.sendScreen(); // Uncomment on Mac to enable Syphon
...

// In setupHandlers.pde: Line 52

...
server = new SyphonServer(this, "Cartography"); // uncomment on Mac to enable Syphon
...
```

Then, you might want to run the App in fullscreen mode (the app and Isadora patch is callibrated for fullscreen). To do so, edit the following two lines in `map_display.pde`:

```java
// map_display.pde: Lines 83 and 84
//size(1200, 600, P2D); // Uncomment for windowed/debug
fullScreen(P2D); // Uncomment for fullscreen
```

Finally, run it or build it! To run, press the run button! To build an executable, the dropdown menu should have an `Export Application...` option that should do the trick.

## API Use

Below is documentation on the interfaces available for each of the components.

### Client Map

The client side shows an map of the world rendered as an SVG image. Users can use the browser's built-in gesture inputs to navigate: single drag to scroll, pinch to zoom, etc. Additionally, users can double-tap to select countries and add them to their journey.

The journey is displayed in a list next to the map. There are also three buttons: `UNDO`, which clears the last element in the list, `RESET`, which resets the map view to its normal values, and `SUBMIT`, which sends the journey data to the server. Users can also tap on a particular list element to remove it from their journey.

The client also exposes a couple functions in the developer console to test the setup:

| Function             | Parameters         | Use                                                           |
|:--------------------:|:------------------:|---------------------------------------------------------------|
| `downloadTest(a, b)` | `number`, `number` | Downloads a dataset with `a` journeys with `b` countries each |
| `testHell(n)`        | `number`           | Takes the current selected journey, and POSTs it `n` times    |

### Server

The server handles requests from the audience clients, and keeps track of the journeys they input. It keeps a `journeys` array with the master log of all journeys.

Currently, the server supports the following routes:

| Route             | Method | Use                                                                                                   |
|:-----------------:|:------:|-------------------------------------------------------------------------------------------------------|
| `'/'`             | `GET`  | Serves the client-side map for audience users                                                         |
| `'/api/submit'`   | `POST` | Receives journey data sent by users in JSON format                                                    |
| `'/api/sync'`     | `GET`  | Used by the Display App to retrieve the full journey data                                             |
| `'/api/update'`   | `POST` | Used by the Display App to retrieve only new journey data (in progress)                               |
| `'/api/download'` | `GET`  | Downloads the current `journeys` array as JSON. Use it to generate override files for the display app |
| `'/api/clear'`    | `GET`  | Allows clearing the `journeys` array if needed, and redirects to `'/'`                                |
| `'/api/test'`     | `GET`  | Shows a version of the client that sends 50 journeys in a burst, for testing purposes                 |
| `'/*'`            | `GET`  | Catch-all, redirects any other request to `'/'`                                                       |

### Display Application

The display application runs as a Processing sketch. It uses the HTTP Requests for Processing library to interface with the server and fetch the journey data, and the OscP5 library to listen for OSC messages that interface with the sketch's global parameters. The app loads the same SVG file used in the client web app into a `PShape` object and splits it for further manipulation.

- NOTE: There seems to be a bug with Processing's P2D OpenGL rendering engine when drawing the country strokes. As it stands, it will cause the application to take a while to start, but should run smoothly afterwards.

Here are the global parameters:

| Name                      | Type                | Use                                                                                     |
|:-------------------------:|:-------------------:|-----------------------------------------------------------------------------------------|
| `pathR`, `pathG`, `pathB` | `int`               | Define color for travel paths                                                           |
| `maxTally`                | `int`               | Number of visits at which a country will reach its darkest/maximum color                |
| `minR`, `minG`, `minB`    | `int`               | Define color for countries with a single visit (lightest/minimum)                       |
| `maxR`, `maxG`, `maxB`    | `int`               | Define color for countries with `maxTally` or more visits (darkest/maximum)             |
| `bgR`, `bgG`, `bgB`       | `int`               | Define background color                                                                 |
| `stR`, `stG`, `stB`       | `int`               | Define country stroke color                                                             |
| `fromBg`                  | `boolean`           | If `true`, min color defaults to background color                                       |
| `animationPathMode`       | `AnimationPathMode` | Defines path drawing method. Can be `LINE`, `ARC` or `SHALLOW_ARC`                      |
| `animationPathTime`       | `int`               | Time (in milliseconds) it takes to trace a bath between two countries                   |
| `animationLoop`           | `boolean`           | Whether to loop the travel animations or not                                            |
| `animationShowMarker`     | `boolean`           | Whether to show a marker at the current point of travel                                 |
| `animationFadeBorders`    | `float`             | Fades from no borders (0) to solid borders (1). Exposed for manual override.            |
| `animationFadeStep`       | `float`             | Defines the speed of the border fade, per frame                                         |
| `animationFadeIn`         | `boolean`           | `true` to fade borders in; `false` to fade them out                                     |
| `animationRadiusFactor`   | `float`             | Determines shallowness of `SHALLOW_ARC`. Minimum is 1 (semicircle)                      |
| `animationGradualColor`   | `boolean`           | Do we color countries as we visit them (in "real-time")?                                |
| `animationColorStep`      | `float`             | Rate at which we fade between country colors                                            |
| `animationColorThreshold` | `int`               | How many visits correspond to a change in color?                                        |
| `animationMaxJourneys`    | `int`               | How many journeys should we display at one time?                                        |
| `debug`                   | `boolean`           | Enable debug logs for OSC callibration?                                                 |
| `syncTime`                | `float`             | Approximate time in seconds between sync requests to server                             |
| `scaleY`                  | `float`             | Scales the map vertically                                                               |
| `yOffset`                 | `float`             | Offsets the map from the top of the screen                                              |
| `minLat`, `maxLat`        | `float`             | Determines minimum and maximum latitudes for coordinate scaling                         |
| `panic`                   | `boolean`           | If `true`, override data is used. Cannot be set to `true` if there is no override data. |

The following global parameters are exposed via OSC:

| Parameter                 | OSC Address                 | Expected Types *    | Range        |
|:-------------------------:|:---------------------------:|:-------------------:|--------------|
| `pathR`, `pathG`, `pathB` | `/pathColor`                | `int`, `int`, `int` | `0..255`     |
| `maxTally`                | `/maxTally`                 | `int`               | `> 0`        |
| `minR`, `minG`, `minB`    | `/minColor`                 | `int`, `int`, `int` | `0..255`     |
| `maxR`, `maxG`, `maxB`    | `/maxColor`                 | `int`, `int`, `int` | `0..255`     |
| `bgR`, `bgG`, `bgB`       | `/bgColor`                  | `int`, `int`, `int` | `0..255`     |
| `stR`, `stG`, `stB`       | `/strokeColor`              | `int`, `int`, `int` | `0..255`     |
| `fromBg`                  | `/fromBg`                   | `int`               | `0..1`       |
| `animationPathMode`       | `/animation/pathMode`       | `int`               | `0..2`       |
| `animationPathTime`       | `/animation/pathTime`       | `int`               | `> 0`        |
| `animationFadeBorders`    | `/animation/fadeBorders`    | `float`             | `0..1`       |
| `animationFadeStep`       | `/animation/fadeStep`       | `float`             | `0..1`       |
| `animationFadeIn`         | `/animation/fadeIn`         | `int`               | `0..1`       |
| `animationRadiusFactor`   | `/animation/radiusFactor`   | `float`             | `>= 1`       |
| `animationColorStep`      | `/animation/colorStep`      | `float`             | `0..1`       |
| `animationColorThreshold` | `/animation/colorThreshold` | `int`               | `>= 1`       |
| `animationMaxJourneys`    | `/animation/maxJourneys`    | `int`               | `> 0`        |
| `debug`                   | `/debug`                    | `int`               | `0..1`       |
| `requestClear()` **       | `/clear`                    | `(none)`            | `N/A`        |
| `syncTime`                | `/syncTime`                 | `float`             | `>= 1`       |
| `scaleY`                  | `/scaleY`                   | `float`             | `> 0`        |
| `yOffset`                 | `/yOffset`                  | `float`             | `>= 0`       |
| `minLat`, `maxLat`        | `/latRange`                 | `float`, `float`    | `< 0`, `> 0` |
| `panic`                   | `/panic`                    | `int`               | `0..1`       |
| `stepPanic()` ***         | `/step`                     | `(none)`            | `N/A`        |

- (*) `boolean` parameters are converted from `int` OSC messages because otherwise the thing breaks.
- (**) Sending any OSC message to `/clear` will call `requestClear` and issue a clear command to the server. It is a blocking operation and will freeze the app for a split second, so I'd recommend using a phone browser and going to `/api/clear` directly.
- (***) Likewise, any OSC message to `/step` should step forward using `stepPanic` and start the next journey in the override. That one shouldn't slow things down.
