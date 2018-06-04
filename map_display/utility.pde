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

  // Add any additional entries to our journey state list
  journeyIndices.resize(journeys.size());
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

// Helper to get coordinate data out of the journey JSON
PVector countryCoord(JSONArray journey, int index) {
  JSONObject data = journey.getJSONObject(index);
  PVector point = new PVector(
    data.getFloat("lon"), 
    data.getFloat("lat"));

  return point;
}

// Ticks the travel indices forward
void animationTick() {
  if (millis() - animationLastTick >= animationPathTime) {
    animationLastTick += animationPathTime;

    // Make sure we don't tick the fist entry on empty data
    if (journeys == null || journeys.getJSONArray(0).size() == 0) {
      return;
    }

    for (int i = 0; i < journeyIndices.size(); ++i) {
      journeyIndices.increment(i);
    }
  }
}

// Function to animate moving planes/points/things across the paths
void animateJourneys() {
  // Make sure we have retrieved journey dtaa already!
  if (journeys == null) {
    return;
  }

  // Animations are in sync; What point of the travel are we at?  
  float t = (float)(millis() % animationPathTime) / (float)animationPathTime;

  // Iterate over our data
  for (int i = 0; i < journeys.size(); ++i) {
    float localT = t;
    // Let's look at our journey
    JSONArray journey = journeys.getJSONArray(i);
    // Empty journey means no data, let's get out!
    if (journey.size() == 0) {
      return;
    }
    // What's our current travel? N countries mean N - 1 travels
    int travelIndex = journeyIndices.get(i);
    if (animationLoop) {
      travelIndex %= (journey.size() - 1);
    }

    // Override and draw full path if not looping and we are done
    if (!animationLoop && journeyIndices.get(i) + 2 > journey.size()) {
      localT = 1;
      travelIndex = journey.size() - 2;
    } 

    // Now, let's look at every point we've travelled through so far
    for (int j = 0; j < travelIndex; ++j) {
      // Draw the travel between countries
      PVector from = countryCoord(journey, j);
      PVector to = countryCoord(journey, j + 1);

      stroke(pathR, pathG, pathB);
      noFill();
      drawTravel(from, to);
    }

    // Where are we at right now? Draw the travel there...
    PVector currentPos = animateTravel(journey, travelIndex, localT);
    // And finally add a marker!
    if (animationShowMarker) {    
      noStroke();
      fill(pathR, pathG, pathB);
      ellipse(currentPos.x, currentPos.y, 5, 5);
    }

    // If we are looping, set our journey index to the temporary value (so that the modulo loops it)
    if (animationLoop) {
      journeyIndices.set(i, travelIndex);
    }
  }
}

// Draws completed travels
void drawTravel(PVector from, PVector to) {
  switch (animationPathMode) {
  case LINE:
    line(from.x*map.width, from.y*map.height, to.x*map.width, to.y*map.height);
    break;
  case ARC:
    // Find the center of our arc and convert to drawing coordinates
    PVector center = PVector.add(from, to);
    center = new PVector(center.x*map.width, center.y*map.height);
    center.div(2.0);
    // Find the rotation of our arc
    PVector heading = PVector.sub(to, from);
    heading = new PVector(heading.x*map.width, heading.y*map.height); // We need real coordinates, not nromalized
    float angle = atan2(heading.y, heading.x); // atan2 takes y first
    // Draw our arc
    boolean invertDirection = false;
    if (angle > HALF_PI || angle < -HALF_PI) {
      invertDirection = true;
    }
    float diameter = heading.mag();
    if (invertDirection) {
      arc(center.x, center.y, diameter, diameter, TWO_PI+angle, PI+angle);
    } else {
      arc(center.x, center.y, diameter, diameter, (PI+angle), TWO_PI+angle);
    }
    break;
  }
}

// Function to animate the current travel in each journey. 
// Returns the (already scaled) coordinate where the point should be drawn for later reuse
PVector animateTravel(JSONArray journey, int index, float t) {
  // From where?
  PVector from = countryCoord(journey, index);
  // To where?
  PVector to = countryCoord(journey, index + 1);
  float x = 0, y = 0;

  noFill();
  stroke(pathR, pathG, pathB);

  switch (animationPathMode) {
  case LINE:
    // So where are we now?
    x = constrain(map(t, 0, 1, from.x, to.x), 0, 1)*map.width;
    y = constrain(map(t, 0, 1, from.y, to.y), 0, 1)*map.height;
    // Finally, draw the path so far!
    line(from.x*map.width, from.y*map.height, x, y);
    break;
  case ARC:
    // Find the center of our arc and convert to drawing coordinates
    PVector center = PVector.add(from, to);
    center = new PVector(center.x*map.width, center.y*map.height);
    center.div(2.0);
    // Find the rotation of our arc
    PVector heading = PVector.sub(to, from);
    heading = new PVector(heading.x*map.width, heading.y*map.height); // We need real coordinates, not normalized
    float angle = atan2(heading.y, heading.x); // atan2 takes y first
    boolean invertDirection = false;
    if (angle > HALF_PI || angle < -HALF_PI) {
      //angle += PI;
      invertDirection = true;
    }
    // Draw our arc
    float diameter = heading.mag();
    float endAngle = map(t, 0, 1, PI+angle, TWO_PI+angle);
    PVector point;
    if (invertDirection) {
      point = arcCC(center.x, center.y, diameter, diameter, endAngle, PI+angle);
    } else {
      point = arcCC(center.x, center.y, diameter, diameter, (PI+angle), endAngle);
    }
    // Calculate our current x,y manually
    x = point.x;
    y = point.y;
    break;
  }

  return new PVector(x, y);
}

// Because apparently Processing does not support counter-clockwise arc drawing
PVector arcCC(float x, float y, float w, float h, float start, float end) {
  beginShape();
  float radX = w/2;
  float radY = h/2;

  float nx = 0, ny = 0;

  if (abs(start-end) > TWO_PI) {
    println("wot");
    if (start > end) {
      start -= TWO_PI;
    } else {
      end -= TWO_PI;
    }
  }

  for (int i = 0; i < 30; ++i) {
    float angle = start > end ? ( end - start > TWO_PI ? map(i, 0, 29, end, end - start - TWO_PI) : map(i, 0, 29, end, end - start)) : map(i, 0, 29, start, end);
    nx = x + radX*cos(angle);
    ny = y + radY*sin(angle);
    vertex(nx, ny);
  }

  endShape();

  return new PVector(nx, ny);
}
