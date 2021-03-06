// Utility function to reset the countries' counts before tallying again
void clearHeatmap() {
  for (String k : countries.keySet()) {
    Country c = countries.get(k);    
    c.resetCount();
  }
}

// Utility function to map colors depending on amount of times visited
// Set fromBg to false to use minColor (minR, minG, minB) as a starting point
// Set fromBg to true to simple interpolate from background to maxColor (maxR, maxG, maxB)
color mapColor(float count) {
  float clamped = constrain(count, 0, maxTally);

  if (!fromBg) {
    if (clamped < 1) {
      return color(
        map(clamped, 0, 1, bgR, minR), 
        map(clamped, 0, 1, bgG, minG), 
        map(clamped, 0, 1, bgB, minB)
        );
    } else {
      return color(
        map(clamped, 1, maxTally, minR, maxR), 
        map(clamped, 1, maxTally, minG, maxG), 
        map(clamped, 1, maxTally, minB, maxB)
        );
    }
  }

  return color(
    map(clamped, 0, maxTally, bgR, maxR), 
    map(clamped, 0, maxTally, bgG, maxG), 
    map(clamped, 0, maxTally, bgB, maxB)
    );
}

// Steps forward in panic mode
void stepPanic() {
  if (panic) {
    panicStep = constrain(panicStep + 1, 0, override.size()-1);
    println(String.format("Panic drawing %d journeys", panicStep));
  }
}

// Colors in country number n in a given journey
void tallyTravel(JSONArray journey, int n) {
  if (n < journey.size()) {
    String country = journey.getJSONObject(n).getString("name");
    countries.get(country).tallyCount();
  }
}

// Gets the tally associated to a particualr point of the journey
int getTally(JSONArray journey, int n) {
  if (n < journey.size()) {
    String country = journey.getJSONObject(n).getString("name");
    return countries.get(country).count;
  }
  return -1;
}

// Requests clear from within the Display App
void requestClear() {
  // If we are overriding, don't even bother
  if (panic) {
    return;
  }

  GetRequest req = new GetRequest(String.format("http://localhost:%d/api/clear", port));

  try {
    req.send();
    println("Clear request sent!");
  } 
  catch (Exception e) {
    println("Clear request failed.");
    return;
  }
}

// Requests full journey data from the server
void requestSync() {
  // If we are overriding, don't even bother
  if (panic) {
    return;
  }

  GetRequest req = new GetRequest(String.format("http://localhost:%d/api/sync", port));
  req.addHeader("Accept", "application/json");

  // Make sure we abort on failure
  try {
    req.send();
    // We should get JSON data, so we parse it
    journeys = parseJSONArray(req.getContent());
  } 
  catch (Exception e) {
    println("Connection to server failed.");
    return;
  }  

  if (!animationGradualColor) {
    // We clear our map before tallying again, if doing instant fill-in
    clearHeatmap();

    // Iterate over the journeys submitted...
    for (int i = 0; i < journeys.size(); ++i) {
      JSONArray journey = journeys.getJSONArray(i);
      // ...and then over the countries visited...
      for (int j = 0; j < journey.size(); ++j) {
        JSONObject country = journey.getJSONObject(j);

        // ...and tally based on country name!
        String n = country.getString("name", "");
        countries.get(n).tallyCount();
      }
    }
  } else {
    // We fill in only new, initial countries if doing gradual fill-in
    tallyFirst(journeys);
    // We must consider the case where we had an empty dataset (1 empty journey) and get new data
    JSONArray journey = journeys.getJSONArray(0);
    if (getTally(journey, 0) == 0) {
      tallyTravel(journey, 0);
    }
  }

  //println(journeys.size(), journeyIndices.size());

  // Did we actually get data?
  if (journeys.size() >= journeyIndices.size() && journeys.getJSONArray(0).size() > 0) {
    // Add any additional entries to our journey state list
    journeyIndices.resize(journeys.size());
  }
  // Or did the data get reset?
  else {
    journeyIndices.clear();
    journeyIndices.resize(1);

    clearHeatmap();
  }
}

// Requests new journey data from the server
// === SEEMS TO USE AN UNSUPPORTED ENCODING, CURRENTLY BREAKS THE SERVER ===
void requestUpdate(JSONArray json) {
  // Get the full data if we have none yet
  if (json == null) {
    requestSync();
  } 
  // Otherwise, we ask only for what we need
  else {
    int count = json.size();
    // Post our current count
    PostRequest post = new PostRequest(String.format("http://localhost:%d/api/update", port));
    post.addData("count", String.valueOf(count));
    post.send();

    //println(post.getContent());
    // Parse our new data!
    JSONArray data = parseJSONArray(post.getContent());

    // Iterate over the new journeys...
    for (int i = 0; i < data.size(); ++i) {
      JSONArray journey = data.getJSONArray(i);
      // ...and then over the countries visited...
      for (int j = 0; j < journey.size(); ++j) {
        JSONObject country = journey.getJSONObject(j);

        // ...and tally based on country name!
        String n = country.getString("name", "");
        countries.get(n).tallyCount();
      }
      // We also add each new journey to our full data object
      journeys.append(journey);
    }
  }
}

// Maps (lon, lat) coordinate received from server to normalized coordinate
PVector mapCoordinates(PVector coord) {
  // Map longitude from -180 .. 180 to 0 .. 1
  float x = map(coord.x, -180, 180, 0, 1);
  // Map latitude from maxLat .. minLat to 0 .. 1 (because Y points down in this context)
  float y = map(coord.y, maxLat, minLat, 0, 1);

  return new PVector(x, y);
}

// Helper to get coordinate data out of the journey JSON
PVector countryCoord(JSONArray journey, int index) {
  JSONObject data = journey.getJSONObject(index);
  try {
    PVector point = new PVector(
      data.getFloat("lon"), 
      data.getFloat("lat"));

    return mapCoordinates(point);
  } 
  catch (Exception e) {
    return new PVector();
  }
}

// Tallies first elements so they show up in the map
void tallyFirst(JSONArray j) {
  JSONArray journey;
  for (int i = journeyIndices.size(); i < j.size(); ++i) {
    journey = j.getJSONArray(i);
    tallyTravel(journey, 0);
  }
}

// Same but only some of them (0 < n < m <= j.size())
void tallyFirst(JSONArray j, int n, int m) {
  int num = m;
  if (num < 1 || num > j.size()) {
    num = j.size();
  }
  JSONArray journey;
  for (int i = n; i < num; ++i) {
    journey = j.getJSONArray(i);
    tallyTravel(journey, 0);
  }
}

// Gets lower bound for journeys to draw
int getMinJourney() {
  int top = getNumJourneys();
  int min = top - animationMaxJourneys;
  return min > 0 ? min : 0;
}

// Gets number of journeys (if normal mode) or current panicStep (if panic mode)
int getNumJourneys() {
  if (panic) {
    return panicStep + 1;
  } else {
    return journeyIndices.size();
  }
}

// I don't want to write this if statement 200826926781 times (jk it's just 2 so far)
JSONArray getJourneyData() {
  // We use override data if panicking, real data otherwise
  if (panic) {
    return override;
  } else {
    return journeys;
  }
}
