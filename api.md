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

| Route           | Method | Use                                                                    |
|:---------------:|:------:|------------------------------------------------------------------------|
| `'/'`           |`GET`   | Serves the client-side map for audience users                          |
| `'/api/submit'` |`POST`  | Receives journey data sent by users in JSON format                     |
| `'/api/sync'`   |`GET`   | Used by the Display App to retrieve the full journey data              |
| `'/api/update'` |`POST`  | Used by the Display App to retrieve only new journey data              |
| `'/api/clear'`  |`GET`   | Allows clearing the `journeys` array if needed, and redirects to `'/'` |
| `'/*'`          |`GET`   | Catch-all, redirects any other request to `'/'`                        |

### Display Application

=== IN PROGRESS ===
