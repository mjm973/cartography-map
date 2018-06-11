// Encapsulates the drawing of the map
void drawMap() {
  // Background is any color we tell it to be
  background(bgR, bgG, bgB); 
  // Moving and scaling the map to its proper position, size, and aspect ratio
  translate(0, yOffset);
  scale(scaleFactor);
  scale(1, scaleY);

  // Drawing the borders
  stroke(map(animationFadeBorders, 0, 1, bgR, stR), 
    map(animationFadeBorders, 0, 1, bgG, stG), 
    map(animationFadeBorders, 0, 1, bgB, stB));

  // Iterate and draw each country separately
  for (String k : countries.keySet()) {
    Country c = countries.get(k);

    // diableStyle allows us to override the SVG's built-in styling
    c.disableStyle();
    fill(mapColor(c.counting));
    c.draw();
  }
}

// Fades country borders in and out
void fadeBorders() {
  if (animationFadeIn) {
    animationFadeBorders += animationFadeStep;
  } else {
    animationFadeBorders -= animationFadeStep;
  }
  animationFadeBorders = constrain(animationFadeBorders, 0, 1);
}

// Ticks the travel indices forward
void animationTick() {
  if (millis() - animationLastTick >= animationPathTime) {
    animationLastTick += animationPathTime;

    // Real data or override data?
    JSONArray journeyData = getJourneyData();

    // Make sure we don't tick the fist entry on empty data
    if (journeyData == null || journeyData.getJSONArray(0).size() == 0) {
      return;
    }
    
    // We tick all things if running normally
    // We tick only until panicStep if in panic mode
    int end = getNumJourneys();

    for (int i = 0; i < end; ++i) {
      journeyIndices.increment(i);
      if (animationGradualColor) {
        int index = journeyIndices.get(i);
        JSONArray journey = journeyData.getJSONArray(i);
        tallyTravel(journey, index);
      }
    }
  }
}

// Function to animate moving planes/points/things across the paths
void animateJourneys() {
  // Are we using real-time data or override data?
  JSONArray journeyData = getJourneyData();

  // Make sure we have retrieved journey data already!
  if (journeyData == null) {
    return;
  }

  // Animations are in sync; What point of the travel are we at?  
  float t = (float)(millis() % animationPathTime) / (float)animationPathTime;

  // Iterate over our data
  for (int i = getMinJourney(); i < getNumJourneys(); ++i) {
    float localT = t;
    // Let's look at our journey
    JSONArray journey = journeyData.getJSONArray(i);
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
  PVector center, heading;
  float angle, diameter, startAngle, endAngle;
  switch (animationPathMode) {
  case LINE:
    line(from.x*map.width, from.y*map.height, to.x*map.width, to.y*map.height);
    break;
  case ARC:
    // Find the center of our arc and convert to drawing coordinates
    center = PVector.add(from, to);
    center = new PVector(center.x*map.width, center.y*map.height);
    center.div(2.0);
    // Find the rotation of our arc
    heading = PVector.sub(to, from);
    heading = new PVector(heading.x*map.width, heading.y*map.height); // We need real coordinates, not normalized
    // Find rotation from horizontal
    angle = atan2(heading.y, heading.x); // atan2 takes y first

    // Draw our arc
    diameter = heading.mag();
    // Show time: find the start and end angles
    if (from.x < to.x) {
      // Simple case: clockwise travel
      startAngle = angle - PI;
      endAngle =angle;
    } else {
      // Awful case: counterclockwise travel
      if (from.y < to.y) {
        startAngle = angle - PI;
      } else {
        startAngle = angle + PI;
      }
      endAngle = startAngle - PI;
    }

    arcCC(center, diameter, startAngle, endAngle);
    break;
  case SHALLOW_ARC:
    // Find the center of our arc and convert to drawing coordinates
    center = PVector.add(from, to);
    center = new PVector(center.x*map.width, center.y*map.height);
    center.div(2.0);
    // Find the rotation of our arc
    heading = PVector.sub(to, from);
    heading = new PVector(heading.x*map.width, heading.y*map.height); // We need real coordinates, not normalized
    // Find rotation from horizontal
    angle = atan2(heading.y, heading.x); // atan2 takes y first

    // Draw our arc
    diameter = heading.mag();
    // Show time: find the start and end angles
    if (from.x < to.x) {
      // Simple case: clockwise travel
      startAngle = angle - PI;
      endAngle = map(1, 0, 1, startAngle, angle);
    } else {
      // Awful case: counterclockwise travel
      if (from.y < to.y) {
        startAngle = angle - PI;
      } else {
        startAngle = angle + PI;
      }
      endAngle = map(1, 0, 1, startAngle, startAngle - PI);
    }

    arcShallow(center, diameter, startAngle, endAngle, angle, animationRadiusFactor, 1);

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

  PVector center, heading, point;
  float angle, diameter, startAngle, endAngle;

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
    center = PVector.add(from, to);
    center = new PVector(center.x*map.width, center.y*map.height);
    center.div(2.0);
    // Find the rotation of our arc
    heading = PVector.sub(to, from);
    heading = new PVector(heading.x*map.width, heading.y*map.height); // We need real coordinates, not normalized
    // Find rotation from horizontal
    angle = atan2(heading.y, heading.x); // atan2 takes y first

    // Draw our arc
    diameter = heading.mag();
    // Show time: find the start and end angles
    if (from.x < to.x) {
      // Simple case: clockwise travel
      startAngle = angle - PI;
      endAngle = map(t, 0, 1, startAngle, angle);
    } else {
      // Awful case: counterclockwise travel
      if (from.y < to.y) {
        startAngle = angle - PI;
      } else {
        startAngle = angle + PI;
      }
      endAngle = map(t, 0, 1, startAngle, startAngle - PI);
    }

    point = arcCC(center, diameter, startAngle, endAngle);
    x = point.x;
    y = point.y;
    break;
  case SHALLOW_ARC:
    // Find the center of our arc and convert to drawing coordinates
    center = PVector.add(from, to);
    center = new PVector(center.x*map.width, center.y*map.height);
    center.div(2.0);
    // Find the rotation of our arc
    heading = PVector.sub(to, from);
    heading = new PVector(heading.x*map.width, heading.y*map.height); // We need real coordinates, not normalized
    // Find rotation from horizontal
    angle = atan2(heading.y, heading.x); // atan2 takes y first

    // Draw our arc
    diameter = heading.mag();
    // Show time: find the start and end angles
    if (from.x < to.x) {
      // Simple case: clockwise travel
      startAngle = angle - PI;
      endAngle = map(t, 0, 1, startAngle, angle);
    } else {
      // Awful case: counterclockwise travel
      if (from.y < to.y) {
        startAngle = angle - PI;
      } else {
        startAngle = angle + PI;
      }
      endAngle = map(t, 0, 1, startAngle, startAngle - PI);
    }

    point = arcShallow(center, diameter, startAngle, endAngle, angle, animationRadiusFactor, t);
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

  for (int i = 0; i < 30; ++i) {
    float angle =  map(i, 0, 29, start, end);
    nx = x + radX*cos(angle);
    ny = y + radY*sin(angle);
    vertex(nx, ny);
  }

  endShape();

  return new PVector(nx, ny);
}

// Refactored overload because PRETTY
PVector arcCC(PVector center, float d, float start, float end) {
  beginShape();
  float rad = d/2;

  float nx = 0, ny = 0;

  for (int i = 0; i < 30; ++i) {
    float angle =  map(i, 0, 29, start, end);
    nx = center.x + rad*cos(angle);
    ny = center.y + rad*sin(angle);
    vertex(nx, ny);
  }

  endShape();

  return new PVector(nx, ny);
}

// You want shallow arcs? You get shallow arcs! YEAH, MATHZ!
PVector arcShallow(PVector mid, float d, float start, float end, float rot, float factor, float t) {
  float rad = d/2;
  float dist = sqrt(rad*rad*(factor*factor - 1));
  PVector offset = new PVector(-sin(rot), cos(rot)).mult(-dist);
  float arc = 2*asin(1/factor);

  float nStart, nEnd;

  // Clockwise
  if (start < end) {
    offset.mult(-1); // Ensure big circle arcs in the right direction
    nEnd = rot + 0.5*(arc-PI);
    nStart = nEnd - arc;
  } 
  // Counterclockwise
  else {
    nStart = rot + 0.5*(arc+PI);
    nEnd = nStart - arc;
  }

  PVector center = PVector.add(mid, offset);
  float arcTo = map(t, 0, 1, nStart, nEnd);

  return arcCC(center, d*factor, nStart, arcTo);
}
