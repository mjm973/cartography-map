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
  LINE, ARC, SHALLOW_ARC
}

// === GLOBAL PARAMETERS ===

// = NETWORK =
float syncTime = 4; // How long between syncs?

// = MAP =
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
// Background color?
int bgR = 255;
int bgG = 255;
int bgB = 255;
// Stroke color?
int stR = 0;
int stG = 0;
int stB = 0;
boolean fromBg = false; // Override min color with background color??
float scaleY = 1.2; // Stretches the map vertically. 1.2 almost clips Antarctica off completely.

// = ANIMATION =
AnimationPathMode animationPathMode = AnimationPathMode.SHALLOW_ARC; // How are we drawing paths between nodes?
int animationPathTime = 3000; // Time it takes to travel between two countries, in ms
boolean animationLoop = false; // Do we loop the paths, or stay at the end of the journey?
boolean animationShowMarker = true; // Show a "vehicle" marker?
float animationFadeBorders = 0; // To fade from no borders to solid borders
float animationFadeStep = 0.01; // How fast to fade from no borders to full borders
boolean animationFadeIn = false; // Enable to fade in; disable to fade out
float animationRadiusFactor = 1.5; // Bigger factor => shallower arcs
boolean animationGradualColor = true; // Do we fill in the countries gradually as we travel?

void setup() {
  size(1200, 600, P2D);
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
}

void draw() {
  background(bgR, bgG, bgB);
  translate(0, 0.5*(height-map.height*scaleFactor));
  scale(scaleFactor);
  scale(1, scaleY);

  stroke(map(animationFadeBorders, 0, 1, bgR, stR), 
    map(animationFadeBorders, 0, 1, bgG, stG), 
    map(animationFadeBorders, 0, 1, bgB, stB));

  // Iterate and draw each country separately
  for (String k : countries.keySet()) {
    Country c = countries.get(k);

    // diableStyle allows us to override the SVG's built-in styling
    c.disableStyle();

    fill(mapColor(c.count));

    c.draw();
  }

  // Tick our travels forward
  animationTick();

  // Fade borders in/out
  fadeBorders();

  // Animation weeeeeee!
  animateJourneys();

  // Every now and then, query the server on the journeys submitted
  if (frameCount % (int)syncTime*frameRate == 0) {
    requestSync();
  }

  // Send image data through Syphon!
  //server.sendScreen();

  //println(frameCount);
}

void mousePressed() {
  switch (mouseButton) {
  case RIGHT:
    animationFadeIn = !animationFadeIn;
    break;
  }
}

void keyPressed() {
  switch (key) {
  case 'q':
  case 'Q':
    animationFadeIn = !animationFadeIn;
    break;
  }
}
