// Loads the map SVG and initializes our data structures
void setupMap() {
  // Load map
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
}

// Loads override data and disables panic mode if it fails
void loadOverride() {
  try {
    // Normally, override data should be loaded
    override = loadJSONArray("override.json");
    println("Loaded override data!");
    println(String.format("Data contains %d journeys.", override.size()));
  } 
  catch (Exception e) {
    // If that fails, we leave it null
    override = null;
    println("Failed to load override data. Disabling panic mode...");
    // And we disable panic
    enablePanic = false;
    // We set panic to false for good measure
    panic = false;
  }
}

// Initializes Syphon and OSC communications
void setupComms() {
  // create Syphon server
  //server = new SyphonServer(this, "Cartography"); // uncomment on Mac to enable Syphon

  // Set up OSC Communication
  osc = new OscP5(this, oscPort);
}
