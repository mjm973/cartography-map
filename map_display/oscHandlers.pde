// OSC magic happens here
void oscEvent(OscMessage message) {
  // Check for address pattern
  //println(message.typetag());
  switch (message.addrPattern()) {
    // == CALLIBRATION ==
    // [int] -> debug
  case "/debug":
    if (message.checkTypetag("i")) {
      debug = message.get(0).intValue() == 1;
      if (debug) {
        println("=== DEBUG MODE ENABLED ===");
      } else {
        println("=== DEBUG MODE DISABLED ===");
      }
    }
    break;
    // [int] -> panic
  case "/panic":
    if (message.checkTypetag("i")) {
      // Panic can only be set if enabled
      // If disabled, it will default to false
      panic = (message.get(0).intValue() == 1) && enablePanic;
      if (debug) {
        println(panic ? "Panic Mode: Override Engaged" : "Panic Mode Disengaged");
      }
    }
    break;
    // [float] -> scaleY
  case "/scaleY":
    if (message.checkTypetag("f")) {
      scaleY = message.get(0).floatValue();
      if (debug) {
        println(String.format("scaleY set to [%f]", scaleY));
      }
    }
    break;
    // [float] -> yOffset
  case "/yOffset":
    if (message.checkTypetag("f")) {
      yOffset = message.get(0).floatValue();
      if (debug) {
        println(String.format("yOffset set to [%f]", yOffset));
      }
    }
    break;
    // [float, float] -> [minLat, maxLat]
  case "/latRange":
    if (message.checkTypetag("ff")) {
      minLat = message.get(0).floatValue();
      maxLat = message.get(1).floatValue();

      if (debug) {
        println(String.format("[minLat, maxLat] set to [%f, %f]", minLat, maxLat));
      }
    }
    break;
    // [float] -> syncTime
  case "/syncTime": 
    if (message.checkTypetag("f")) {
      syncTime = message.get(0).floatValue();
      if (debug) {
        println(String.format("syncTime set to [%f]", syncTime));
      }
    }
    // == MAP PARAMETERS ==
    // [int, int, int] -> [colorR, colorG, colorB]
  case "/pathColor":
    if (message.checkTypetag("iii")) {
      pathR = message.get(0).intValue();
      pathG = message.get(1).intValue();
      pathB = message.get(2).intValue();

      if (debug) {
        println(String.format("pathColor set to [%d, %d, %d]", pathR, pathG, pathB));
      }
    }
    break;
  case "/minColor":
    if (message.checkTypetag("iii")) {
      minR = message.get(0).intValue();
      minG = message.get(1).intValue();
      minB = message.get(2).intValue();

      if (debug) {
        println(String.format("minColor set to [%d, %d, %d]", minR, minG, minB));
      }
    }
    break;
  case "/maxColor":
    if (message.checkTypetag("iii")) {
      maxR = message.get(0).intValue();
      maxG = message.get(1).intValue();
      maxB = message.get(2).intValue();

      if (debug) {
        println(String.format("maxColor set to [%d, %d, %d]", maxR, maxG, maxB));
      }
    }
    break;
  case "/bgColor":
    if (message.checkTypetag("iii")) {
      bgR = message.get(0).intValue();
      bgG = message.get(1).intValue();
      bgB = message.get(2).intValue();

      if (debug) {
        println(String.format("bgColor set to [%d, %d, %d]", bgR, bgG, bgB));
      }
    }
    break;
  case "/strokeColor":
    if (message.checkTypetag("iii")) {
      stR = message.get(0).intValue();
      stG = message.get(1).intValue();
      stB = message.get(2).intValue();

      if (debug) {
        println(String.format("strokeColor set to [%d, %d, %d]", stR, stG, stB));
      }
    }
    break;
    // [int] -> fromBg
  case "/fromBg":
    if (message.checkTypetag("i")) {
      fromBg = message.get(0).intValue() == 1;

      if (debug) {
        println(String.format("fromBg set to [%s]", fromBg));
      }
    }
    break;
    // == ANIMATION ==
    // [int] -> animationPathMode
  case "/animation/pathMode":
    if (message.checkTypetag("i")) {
      switch (message.get(0).intValue()) {
      case 0:
        animationPathMode = AnimationPathMode.LINE;
        if (debug) {
          println("animationPathMode set to LINE");
        }
        break;
      case 1:
        animationPathMode = AnimationPathMode.ARC;
        if (debug) {
          println("animationPathMode set to ARC");
        }
        break;
      default:
        animationPathMode = AnimationPathMode.SHALLOW_ARC;
        if (debug) {
          println("animationPathMode set to SHALLOW_ARC");
        }
        break;
      }
    }
    break;
    // [int] -> animationPathTime
  case "/animation/pathTime":
    if (message.checkTypetag("i")) {
      animationPathTime = message.get(0).intValue();

      if (debug) {
        println(String.format("animationPathTime set to [%d]", animationPathTime));
      }
    }
    break;
    // [float] -> animationFadeBorders
  case "/animation/fadeBorders": 
    if (message.checkTypetag("f")) {
      animationFadeBorders = message.get(0).floatValue();

      if (debug) {
        println(String.format("animationFadeBorders set to [%f]", animationFadeBorders));
      }
    }
    break;
    // [float] -> animationFadeStep
  case "/animation/fadeStep":
    if (message.checkTypetag("f")) {
      animationFadeStep = message.get(0).floatValue();

      if (debug) {
        println(String.format("animationFadeStep set to [%f]", animationFadeStep));
      }
    }
    break;
    // [int] -> animationFadeIn
  case "/animation/fadeIn":
    if (message.checkTypetag("i")) {
      animationFadeIn = message.get(0).intValue() == 1;
      if (debug) {
        println(animationFadeIn ? "Fading in!" : "Fading out!");
      }
    }
    break;
    // [float] -> animationRadiusFactor
  case "/animation/radiusFactor":
    if (message.checkTypetag("f")) {
      animationRadiusFactor = message.get(0).floatValue();


      if (debug) {
        println(String.format("animationRadiusFactor set to [%f]", animationRadiusFactor));
      }
    }
    break;
    // [float] -> animationColorStep
  case "/animation/colorStep": 
    if (message.checkTypetag("f")) {
      animationColorStep = message.get(0).floatValue();

      if (debug) {
        println(String.format("animationColorStep set to [%f]", animationColorStep));
      }
    }
    break;
    // [int] -> animationColorThreshold
  case "/animation/colorThreshold":
    if (message.checkTypetag("i")) {
      animationColorThreshold = message.get(0).intValue();

      if (debug) {
        println(String.format("animationColorThreshold set to [%d]", animationColorThreshold));
      }
    }
    break;
  }
}
