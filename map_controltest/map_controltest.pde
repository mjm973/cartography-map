import netP5.*;
import oscP5.*;

OscP5 osc;
NetAddress mapDisplay;

boolean debug = false;

void setup() {
  size(400, 400);
  frameRate(15);
  osc = new OscP5(this, 8888);
  mapDisplay = new NetAddress("127.0.0.1", 9999);
}

void draw() {
  background(0, map(mouseX, 0, width, 0, 255), map(mouseY, 0, height, 0, 255));
  
  OscMessage off = new OscMessage("/yOffset");
  off.add(float(mouseY));
  OscMessage scale = new OscMessage("/scaleY");
  scale.add(map(mouseX, 0, width, 0.5, 1.5));
  
  osc.send(off, mapDisplay);
  osc.send(scale, mapDisplay);
}

void mousePressed() {
  debug = !debug;
  
  OscMessage mess = new OscMessage("/debug");
  mess.add(debug ? 1 : 0);
  osc.send(mess, mapDisplay);
}
