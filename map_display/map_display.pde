import netP5.*;
import oscP5.*;

import codeanticode.syphon.*; // UNCOMMENT
import http.requests.*;

SyphonServer server; // Uncomment on Mac to enable Syphon UNCOMMENT
OscP5 osc;
NetAddress remote;

PShape map; // Our SVG map
HashMap<String, Country> countries; // Map split into individual countries for individual styling
JSONArray journeys = null; // Our data!
JSONArray override = null; // Override data for panic situation
boolean enablePanic = true; // Allows enabling panic if override data is available.
int panicStep = 0; // Used to step through override journeys sequentially

int port = 80;

IntList journeyIndices; // To keep track where we are in each journey

float scaleFactor; // Caching the math to rescale our svg

double animationLastTick = 0; // Used to keep track of the last time the index increased

final int oscPort = 9999;

enum AnimationPathMode {
  LINE, ARC, SHALLOW_ARC
}

// === GLOBAL PARAMETERS ===

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
int maxTally = 7; // How many visits to reach maxColor?
// Background color?
int bgR = 255;
int bgG = 255;
int bgB = 255;
// Stroke color?
int stR = 0;
int stG = 0;
int stB = 0;
boolean fromBg = false; // Override min color with background color??

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
float animationColorStep = 0.05; // How fast we fade between country colors?
int animationColorThreshold = 1; // How many visits correspond to a change in color?
int animationMaxJourneys = 100; // How many journeys to display at a time?

// = CALIBRATION =
boolean debug = false; // Controls print statements for callibration and debug
float syncTime = 4; // How long between syncs?
float scaleY = 1.4125; // Stretches the map vertically. 1.4125 is default
float yOffset = 64; // Offset from the top to position map. 64 is default (MacBook fullscreen)
// Latitude range for coordinate scaling
float maxLat = 83;
float minLat = -90;
boolean panic = false; // Flip to true to engage preset override

void setup() {
  //size(1200, 600, P2D); // Uncomment for windowed/debug
  fullScreen(P2D); // Uncomment for fullscreen

  // Map and data loading and setup
  setupMap();
  // Panic mode override loading
  loadOverride();
  // Syphon and OSC initialization
  setupComms();
}

void draw() {
  // Draw our map!
  drawMap();
  // Fade borders in/out
  fadeBorders();
  // Tick our travels forward
  animationTick();
  // Animation weeeeeee!
  animateJourneys();

  // Every now and then, query the server on the journeys submitted
  if (frameCount % (int)syncTime*frameRate == 0) {
    requestSync();
  }

  // Send image data through Syphon! UNCOMMENT
  server.sendScreen(); // Uncomment on Mac to enable Syphon
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
  case 'x':
  case 'X':
    // Only allow panic mode if enabled (i.e. if there is override data)
    if (enablePanic) {
      panic = !panic;
      if (panic) {
        clearHeatmap();
        journeyIndices.clear();
        journeyIndices.resize(override.size());
        tallyFirst(override, 0, 1);
      } else {
        clearHeatmap();
        journeyIndices.clear();
        journeyIndices.resize(journeys.size());
        tallyFirst(journeys, 0, 1);
      }
    }
    break;
  case ' ':
    requestClear();
    break;
  case 'z':
  case 'Z':
    stepPanic();
    break;
  }
}
