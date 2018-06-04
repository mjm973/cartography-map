import codeanticode.syphon.*;
import http.requests.*;

//SyphonServer server;

PShape map; // Our SVG map
HashMap<String, Country> countries; // Map split into individual countries for individual styling
JSONArray journeys; // Our data!
IntList journeyIndices; // To keep track where we are in each journey

float scaleFactor; // Caching the math to rescale our svg

double animationLastTick = 0; // Used to keep track of the last time the index increased

enum AnimationPathMode {
  LINE, ARC
}

// === GLOBAL PARAMETERS ===

// = NETWORK =
float syncTime = 4; // How long between syncs?

// = COLORS =
// Travel path color?
int pathR = 187;
int pathG = 16;
int pathB = 36;
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

// = ANIMATION =
AnimationPathMode animationPathMode = AnimationPathMode.ARC; // How are we drawing paths between nodes?
int animationPathTime = 3000; // Time it takes to travel between two countries, in ms
boolean animationLoop = false; // Do we loop the paths, or stay at the end of the journey?
boolean animationShowMarker = true; // Show a "vehicle" marker?
float animationFadeBorders = 0; // To fade from no borders to solid borders
float animationFadeStep = 0.001; // How fast to fade from no borders to full borders
boolean animationFadeIn = false; // Enable to fade in; disable to fade out

void setup() {
  size(1200, 600);
  //fullScreen(P2D);
  map = loadShape("countries_lowres.svg");

  // Create our hashmap of countries
  countries = new HashMap<String, Country>();
  int count = map.getChild(0).getChildCount();

  // Iterate through our SVG to extract individual shapes
  for (int i = 0; i < count; ++i) {
    PShape country = map.getChild(0).getChild(i);
    Country c = new Country(country);
    countries.put(c.name, c);
  }

  // Mathemagics to properly scale our map to the display size
  float svgAspect = map.width/map.height;
  float scaledFullHeight = svgAspect*height;
  if (scaledFullHeight > width) {
    scaleFactor = width/map.width;
  } else {
    scaleFactor = svgAspect;
  }
  
  // Create our list with journey states
  journeyIndices = new IntList();

  // create Syphon server
  //server = new SyphonServer(this, "Cartography");
  //println(svgAspect);
}

void draw() {
  background(255);
  scale(scaleFactor);
  // Iterate and draw each country separately
  for (String k : countries.keySet()) {
    Country c = countries.get(k);

    // diableStyle allows us to override the SVG's built-in styling
    c.disableStyle();
    if (animationFadeBorders == 0) {
      noStroke();
    } else {
      stroke((1-animationFadeBorders)*255);
    }
    fill(mapColor(c.count));

    c.draw();
  }

  animationTick();

  if (animationFadeIn) {
    animationFadeBorders += animationFadeStep;
  } else {
    animationFadeBorders -= animationFadeStep;
  }
  animationFadeBorders = constrain(animationFadeBorders, 0, 1);

  animateJourneys();

  // Every now and then, query the server on the journeys submitted
  if (frameCount % (int)syncTime*frameRate == 0) {
    requestSync();
  }
  
  //server.sendScreen();
}

void mousePressed() {
  switch (mouseButton) {
  case RIGHT:
    animationFadeIn = !animationFadeIn;
    break;
  }
}
