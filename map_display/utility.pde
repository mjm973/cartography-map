// Utility function to reset the countries' counts before tallying again
void clearHeatmap() {
  for (String k : countries.keySet()) {
    Country c = countries.get(k);    
    c.resetCount();
  }
}

// Utility function to map colors depending on amount of times visited
// Set fromWhite to false to use the lightest green (14, 223, 65) as a starting point
// Set fromWhite to true to simple interpolate from white to darkest green (6, 94, 28)
color mapColor(int count) {
  if (!fromWhite) {
    if (count == 0) {
      return color(255, 255, 255);
    } else {
      return color(
        map(count, 0, maxTally, minR, maxR), 
        map(count, 0, maxTally, minG, maxG), 
        map(count, 0, maxTally, minB, maxB)
        );
    }
  }

  return color(
    map(count, 0, maxTally, 255, maxR), 
    map(count, 0, maxTally, 255, maxG), 
    map(count, 0, maxTally, 255, maxB)
    );
}

// Requests full journey data from the server
void requestSync() {
  GetRequest req = new GetRequest("http://localhost:4242/api/sync");
    req.addHeader("Accept", "application/json");
    req.send();

    // We should get JSON data, so we parse it
    journeys = parseJSONArray(req.getContent());

    // We clear our map before tallying again
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
    PostRequest post = new PostRequest("http://localhost:4242/api/update");
    post.addData("count", String.valueOf(count));
    post.send();
    
    println(post.getContent());
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

// Function to animate moving planes/points/things across the paths
void animatePoints() {
  // Make sure we have retrieved journey dtaa already!
  if (journeys == null) {
    return;
  }
  
  // Animations are in sync; What point of the travel are we at?  
  float t = (float)(millis() % animationPathTime) / (float)animationPathTime;
  
  // Iterate over our data
  for (int i = 0; i < journeys.size(); ++i) {
    // Let's look at our journey
    JSONArray journey = journeys.getJSONArray(i);
    // Now, let's look at every point
    for (int j = 0; j < journey.size(); ++j) {
      // What's our current travel? N countries mean N - 1 travels
      int travelIndex = animationIndex % (journey.size() - 1);
      // From where?
      JSONObject fromData = journey.getJSONObject(travelIndex);
      PVector from = new PVector(
        fromData.getFloat("lon"), 
        fromData.getFloat("lat"));
      // To where?
      JSONObject toData = journey.getJSONObject(travelIndex + 1);
      PVector to = new PVector(
        toData.getFloat("lon"), 
        toData.getFloat("lat"));
      // So where are we now?
      float x = constrain(map(t, 0, 1, from.x, to.x), 0, 1);
      float y = constrain(map(t, 0, 1, from.y, to.y), 0, 1);
      // Finally!
      noStroke();
      fill(187, 16, 36);
      ellipse(map.width * x, map.height * y, 10, 10);
    }
  }
}
