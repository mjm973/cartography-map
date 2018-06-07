// Class to encapsulate country rendering funtionality
class Country {
  public String name;
  public float lon;
  public float lat;
  PShape shape;

  int count = 0;
  float counting = 0;

  Country(PShape svg) {
    shape = svg;
    name = svg.getName();
    //lon = lo;
    //lat = la;
  }

  Country(PShape svg, String n) {//, float lo, float la) {
    shape = svg;
    name = n;
    //lon = lo;
    //lat = la;
  }

  public void draw() {
    shape(shape);
    counting = constrain(counting + animationColorStep, 0, count);
  }

  public void draw(float w, float h) {
    shape(shape, 0, 0, w, h);
  }

  public void disableStyle() {
    shape.disableStyle();
  }

  public void resetCount() {
    count = 0;
  }

  public void tallyCount() {
    ++count;
  }
}
