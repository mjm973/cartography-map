import http.requests.*;
import java.util.regex.*;

PShape map; // Our SVG map
HashMap<String, Country> countries; // Map split into individual countries for individual styling
JSONArray journeys; // Our data!

float scaleFactor; // Caching the math to rescale our svg

float syncTime = 4; // How long between syncs?
// Color at 1 visit?
int minR = 14;
int minG = 223;
int minB = 65;
// Color at maxTally visits?
int maxR = 6;
int maxG = 94;
int maxB = 28;
int maxTally = 10; // How many visits to reach maxColor?
boolean fromWhite = false; // Override min color with white?

void setup() {
  size(1200, 600);
  map = loadShape("countries.svg");

  // Create our hashmap of countries
  countries = new HashMap<String, Country>();
  int count = map.getChild(0).getChildCount();

  // Iterate through our SVG to extract individual shapes
  for (int i = 0; i < count; ++i) {
    PShape country = map.getChild(0).getChild(i);
    Country c = new Country(country);
    countries.put(c.name, c);
  }
  
  float svgAspect = map.width/map.height;
  float scaledFullHeight = svgAspect*height;
  if (scaledFullHeight > width) {
    scaleFactor = width/map.width;
  } else {
    scaleFactor = svgAspect;
  }
}

void draw() {
  background(255);
  scale(scaleFactor);
  // Iterate and draw each country separately
  for (String k : countries.keySet()) {
    Country c = countries.get(k);

    // diableStyle allows us to override the SVG's built-in styling
    c.disableStyle();
    noStroke();
    fill(mapColor(c.count, false));
    
    c.draw();
  }

  // Every now and then, query the server on the journeys submitted
  if (frameCount % (int)syncTime*frameRate == 0) {
    requestSync();
  }
}
