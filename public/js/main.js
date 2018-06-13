var tap = null; // To determine whether we have a single or double tap
var journey = []; // Keeps track of the countries selected to be sent to the server
var yScale = 1.4125;
var pz; // Handles panning and zooming (thanks js libraries)

// Checks if we have less than the maximum number of countries
function tooManyCountries() {
  var realList = journey.filter(function(c) {
    return !(c === null);
  })

  return !(realList.length < 9);
}

// Returns the last country, skipping null entries
function lastCountry() {
  var realList = journey.filter(function(c) {
    return !(c === null);
  })

  return realList[realList.length-1];
}

// Helper to add a country to the journey array and list
function addCountry(c, flag) {
  // Make sure we don't add too many countries
  if (tooManyCountries()) {
    return;
  }

  // Style the country
  c.classList.add('selected');
  // Add it but only if it isn't already the latest point in the journey
  if (lastCountry() !== c.id) {
    // Add to journey array
    journey.push(c.id);

    // Find list
    var countryList = document.getElementById('country-list');
    // Create new item
    var item = document.createElement('li');
    var cont = document.createElement('div');
    item.appendChild(cont);
    var t = document.createTextNode(c.id);
    cont.appendChild(t);

    // Append flag if there is one
    if (flag) {
      var flagEl = document.createElement('img');
      flagEl.classList.add('flag');
      flagEl.src = `/static/img/flags/${flag}`;
      cont.appendChild(flagEl);
    }

    // Give item an index
    item.dataset.i = journey.length-1;
    // Event listener to allow for removal
    item.addEventListener('click', function(e)   {
      e.preventDefault();
      remCountry(item, item.dataset.i);
    })

    // add item to list
    countryList.appendChild(item);
  }
}

// Helper to undo last country added
function popCountry()   {
  var country = journey.pop();
  if (!journey.includes(country) && country !== null) {
    document.getElementById(country).classList.remove('selected');
  }

  var countryList = document.getElementById('country-list');
  countryList.removeChild(countryList.lastChild);
}

// Helper to remove specific countries from journey
function remCountry(elt, i)   {
  var country = elt.textContent;
  journey[i] = null;
  if (!journey.includes(country)) {
    document.getElementById(country).classList.remove('selected');
  }

  var countryList = document.getElementById('country-list');
  countryList.removeChild(elt);
}

// Loads country + flag data from our JSON file
function loadData(cb)  {
  fetch('/static/countries.json')
    .then(function(res)  {
      return res.json();
    })
    .then(function(data)  {
      cb(data);
    })
}

// Binds mouse and touch events to country regions. Passes flag data through for the country list.
function addCountryEvents(country, tag, flag)  {
  // // === Desktop/debug events ===
  // // 'click' < double tap
  // country.addEventListener('click', (e)  {
  //   console.log(country.id);
  //   addCountry(country, flag);
  // });
  // // 'mouseenter' < 'touchstart'
  // country.addEventListener('mouseenter', (e)  {
  //   tag.style.left = `${e.clientX}px`;
  //   tag.style.top = `${e.clientY}px`;
  //   tag.classList.remove('hidden');
  // });
  // // 'mouseleave' < 'touchend'
  // country.addEventListener('mouseleave', (e)  {
  //   tag.classList.add('hidden');
  // });

  // === Mobile/final events ===
  // 'touchstart' handles single touch (show tag) and double tap (select country)
  country.addEventListener('touchstart', function(e)  {
    // If we haven't tapped recently or we are tapping with several fingers, reset the counter
    if (!tap || e.touches.length > 1) {
      tap = setTimeout(function()  {
        tap = null;
      }, 300);
    }
    // If we do a second tap with a single finger, trigger double tap!
    else {
      clearTimeout(tap);
      tap = null;

      e.preventDefault();
      addCountry(country, flag);
    }

    // Show country tag but only if we are single touching
    if (e.touches.length === 1) {
     // e.preventDefault();

      var touch = e.touches[0];
      tag.style.left = `${touch.clientX - 150}px`;
      tag.style.top = `${touch.clientY - 150}px`;
      tag.classList.remove('hidden');
    } else {
      tag.classList.add('hidden');
    }
  });

  // 'touchend' handles the end of a touch (hide tag)
  country.addEventListener('touchend', function(e)  {
    // tag.classList.add('hidden');
    clearTags();
  });

}

// Helper to convert from (longitude, latitude) to normalized SVG (x,y) coordinates
function earthToSvg(_lon, _lat)  {
  var lon = parseFloat(_lon);
  var lat = parseFloat(_lat);

  var tx = (lon + 180) / 360;
  var ty = 1 - (lat + 85) / 170; // Latitudes close to 90 are truncated

  return {
    x: tx,
    y: ty
  };
}

function tagCountries(data)  {
  // Get all our country shapes
  var countries = document.getElementsByTagName('path');

  // For convenience, let's take the names into a separate array
  var countryNames = [];
  for (var i = 0; i < countries.length; ++i) {
    countryNames.push(countries[i].id);
  }

  // Filter our data (flag + coordinates) based on actual matches with our map
  var matches = data.filter(function(entry) {
    return countryNames.includes(entry.name);
  })

  // Build a match object for easy dictionary access
  var matchObj = {};
  for (var i = 0; i < matches.length; ++i) {
    var match = matches[i];
    var entry = {
      lat: match.latitude,
      lon: match.longitude,
      flag: match.flag_128
    };

    matchObj[match.name] = entry;
  }

  // Iterate through countries to set them all up
  for (var i = 0; i < countries.length; ++i) {
    // Pick a country
    var country = countries[i];

    // Kill Antarctica soz
    if (country.id === "Antarctica") {
      var group = country.parentNode;
      group.removeChild(country);
      continue;
    }

    // Add coordinate data
    var countryData = matchObj[country.id];
    var flag = undefined;
    // A few regions aren't in the dataset so we check to skip them
    if (countryData) {
      country.dataset.lat = countryData.lat;
      country.dataset.lon = countryData.lon;
      flag = countryData.flag;
    }

    // Create a tag for it
    var tag = document.createElement('div');
    tag.classList.add('hidden', 'tag-bg', 'tag');
    var p = document.createElement('p');
    p.classList.add('tag-text');
    var txt = document.createTextNode(country.id);
    p.appendChild(txt);
    tag.appendChild(p);
    document.body.appendChild(tag);

    // Bind events to the country shape
    addCountryEvents(country, tag, flag);
  }
}

// POSTs the journey data to the server to be recorded and displayed
function postJourney()  {
  // ARE WE TESTING A HELL CLIENT??????
  var testElem = document.getElementById('test');
  var isTest = testElem.dataset.test === '1';
  console.log(isTest);

  // Remove leftover null elements from our journey
  var cleanJourney = journey.filter(function(entry) {
    return entry !== null;
  }).map(function(entry) {
    var country = document.getElementById(entry);
    var coord = earthToSvg(country.dataset.lon, country.dataset.lat);
    return {
      name: entry,
      lon: country.dataset.lon,
      lat: country.dataset.lat
    };
  });
  // ONE COUNTRY IS NOT A JOURNEY GUYS!
  if (cleanJourney.length < 2) {
    return;
  }
  // POST data to the server
  var data = JSON.stringify(cleanJourney);
  var numTimes = isTest ? 50 : 1;
  var postRequest = function() {
    console.log('sending...');
    fetch('/api/submit', {
      body: data,
      headers: {
        'content-type': 'application/json'
      },
      method: 'POST'
    }).then(function(res) {
      // Make sure our submission made it through
      if (res.ok) {
        // Clear our journey once we are done
        while (journey.length > 0) {
          // We use popCountry to ensure the list and map get cleared as well
          popCountry();
        }
      }
    });
  }

  for (var i = 0; i < numTimes; ++i) {
    postRequest();
  }
}

// To test hell clients from the console
function testHell(n)  {
  // Remove leftover null elements from our journey
  var cleanJourney = journey.filter(function(entry) {
    return entry !== null;
  }).map(function(entry) {
    var country = document.getElementById(entry);
    var coord = earthToSvg(country.dataset.lon, country.dataset.lat);
    return {
      name: entry,
      lon: country.dataset.lon,
      lat: country.dataset.lat
    };
  });
  // Abort if data is empty!
  if (cleanJourney.length === 0) {
    return;
  }
  // POST data to the server
  var data = JSON.stringify(cleanJourney);
  var postRequest = function() {
    console.log('sending...');
    fetch('/api/submit', {
      body: data,
      headers: {
        'content-type': 'application/json'
      },
      method: 'POST'
    }).then(function(res) {
      // Make sure our submission made it through
      if (res.ok) {
        // Clear our journey once we are done
        while (journey.length > 0) {
          // We use popCountry to ensure the list and map get cleared as well
          popCountry();
        }
      }
    });
  }

  for (var i = 0; i < n; ++i) {
    postRequest();
  }
}

function getPinch(e)  {
  e.preventDefault();
  var x1 = e.touches.item(0).screenX;
  var y1 = e.touches.item(0).screenY;
  var x2 = e.touches.item(1).screenX;
  var y2 = e.touches.item(1).screenY;
  var dx = x2 - x1;
  var dy = y2 - y1;

  var px1 = touchBuffer[0].screenX;
  var py1 = touchBuffer[0].screenY;
  var px2 = touchBuffer[1].screenX;
  var py2 = touchBuffer[1].screenY;
  var pdx = px2 -px1;
  var pdy = py2 - py1;

  var dist = Math.sqrt(dx*dx + dy*dy);
  var pdist = Math.sqrt(pdx*pdx + pdy*pdy);

  return {
    scale: dist/pdist,
    x: (x1 + x2) / 2,
    y: (y1 + y2) / 2
  };
}

function getSlideDelta(e)  {
  // e.preventDefault();

  var x = e.touches.item(0).screenX;
  var y = e.touches.item(0).screenY;
  var px = touchBuffer[0].screenX;
  var py = touchBuffer[0].screenY;

  var dx = x - px;
  var dy = y - py;

  return {
    x: dx,
    y: dy
  };
}

// var touchBuffer = [];
// var mapScale = 1;
// var scaleBuffer;
// var pinchCenter= {
//   x: 1, y: 1,
//   xp: 0, yp: 0
// }
// var xPos = 0, yPos = 0;
// var xBuf = 0, yBuf = 0;
var w = 0, h = 0;

function resetView() {
  // mapScale = 1;
  // scaleBuffer = 1;
  // xPos = 0;
  // xBuf = 0;
  // yPos = 0;
  // yBuf = 0;
  //
  // var map = document.getElementById('map-container');
  // map.style.transform = `translateX(${xPos}px) translateY(${yPos}px) scale(${mapScale})`;
  var t = pz.getTransform();

  pz.zoomAbs(0, 0, 1);
  boundMap(pz);
  scaleStrokes(pz);
}

// Use pinchzoom's data to scale SVG strokes
function scaleStrokes(pz)  {
  var countries = document.getElementsByTagName('path');
  var countryList = Array.from(countries);

  var scale = pz.getTransform().scale;

  countryList.forEach(function(country)  {
    country.style.strokeWidth = 1/scale;
  });
}

// Use pinchzoom's data to keep map in bounds
function boundMap(pz) {
  var map = document.getElementById('map-container');
  var t = pz.getTransform();
  var maxX = 0;
  var maxY = 0;
  var minX = w - map.clientWidth*t.scale;
  var minY = h - map.clientHeight*t.scale;

  console.log(t);

  if (t.x < minX) {
    pz.moveTo(minX, t.y);
    // pz.getTransform().x = minX;
  } else if (t.x > maxX) {
    pz.moveTo(maxX, t.y);
    // pz.getTransform().x = maxX;
  }

  if (t.y < minY) {
    pz.moveTo(t.x, minY);
  } else if (t.y > maxY) {
    pz.moveTo(t.x, maxY);
  }
}

// Because events are weird so let's brute force this thing
function clearTags()  {
  var tags = document.getElementsByClassName('tag');
  var tagList = Array.from(tags);

  tagList.forEach(function(tag)  {
    tag.classList.add('hidden');
  })
}

// Phones phones phones
function isLandscape()  {
  return window.innerWidth > window.innerHeight;
}

// Generate a large JSON file to test the display app
function downloadTest(n, m = 9)  {
  var numJourneys = n;
  var numCountries =  m <= 9 ? (m > 1 ? m : 3) : 9;

  var countries = document.getElementsByTagName('path');
  countries = Array.from(countries);
  var result = [];
  for (var i = 0; i < numJourneys; ++i) {
    var journey = [];
    for (var j = 0; j < numCountries; ++j) {
      var country = countries[Math.floor(Math.random()*countries.length)];
      var entry = {
        name: country.id,
        lon: country.dataset.lon,
        lat: country.dataset.lat
      };
      journey.push(entry);
    }
    result.push(journey);
  }

  var data = JSON.stringify(result);
  var dataStr = `data:text/json;charset=utf-8,${encodeURIComponent(data)}`;
  var elem = document.getElementById('download');
  elem.setAttribute('href', dataStr);
  elem.setAttribute('download', 'test.json');
  elem.click();
}

document.addEventListener('DOMContentLoaded', function()  {
  console.log(isLandscape());
  loadData(tagCountries);

  var map = document.getElementById('map-container');
  w = map.clientWidth;
  h = map.clientHeight;
  var svgGroup = document.getElementById('ne_countries');
  pz = panzoom(map, {
    minZoom: 1,
    maxZoom: 20,
    zoomDoubleClickSpeed: 1,
    smoothScroll: false,
    zoomSpeed: 0.1,
    bounds: {
      left: 0,
      right: w,
      top: 0,
      bottom: h
    },
    onTouch: function(e) {
      return false;
    }
  });

  console.log(pz.getTransform());

  var svg = map.firstChild;


  // Detect orientation change to keep scroll magic working
  window.addEventListener('orientationchange', function(e)  {
    w = map.clientWidth;
    h = map.clientHeight;
  });

  // Disable pinch-zooming on country list
  var listArea = document.getElementById('list-container');
  listArea.addEventListener('touchmove', function(e)  {
    if (e.touches.length >= 2) {
      e.preventDefault();
    }
  });

  // map.addEventListener('touchstart', function(e)  {
  //   touchBuffer = [];
  //   for (var i = 0; i < e.touches.length; ++i) {
  //     touchBuffer.push(e.touches[i]);
  //   }
  //
  //   // var t = e.touches[0];
  //   // console.log(`(${t.clientX}, ${t.clientY})`)
  //   if (e.touches.length === 2) {
  //     var pinch = getPinch(e);
  //     pinchCenter = {
  //       x: pinch.x,
  //       y: pinch.y
  //     };
  //   }
  // });
  map.addEventListener('touchend', function(e)  {
    // mapScale = scaleBuffer;
    if (e.touches.length === 0) {
      clearTags();
      // xPos = xBuf;
      // yPos = yBuf;
      // touchBuffer = [];
    }
  });
  map.addEventListener('touchmove', function(e) {
    e.preventDefault();
    if (e.touches.length === 2) {
      scaleStrokes(pz);
    }
    boundMap(pz);
    // console.log(pz.getTransform());
  });
  // map.addEventListener('touchmove', function(e)  {
  //   if (e.touches.length >= 2) {
  //     var pinch = getPinch(e);
  //     var scale = pinch.scale;
  //     scaleBuffer = mapScale*scale;
  //
  //     scaleBuffer = scaleBuffer > 1 ? scaleBuffer : 1;
  //
  //     var dx = pinch.x - pinchCenter.x;
  //     var dy = pinch.y - pinchCenter.y;
  //
  //     xBuf = xPos + dx;
  //     yBuf = yPos + dy;
  //
  //     // xBuf = xPos-pinchCenter.x
  //     // yBuf = (pinch.y)*(scaleBuffer-1)/2;
  //
  //     // MATH SORCERY I ONLY HALF UNDERSTAND
  //     var upperX = w*(scaleBuffer-1)/2;
  //     var lowerX = isLandscape() ? -w*(scaleBuffer-1)/2 : 0; // No clue why this is needed but it fixes landscape so yeah
  //     var upperY = h*(scaleBuffer-1)/(2);
  //     var lowerY = -upperY;
  //
  //     if (xBuf < lowerX) {
  //       xBuf = lowerX;
  //     } else if (xBuf > upperX) {
  //       xBuf = upperX;
  //     }
  //
  //     // Y is different because map is centered vertically I think?
  //     if (yBuf < lowerY) {
  //       yBuf = 0 - h*(scaleBuffer-1)/(2);
  //     } else if (yBuf > upperY) {
  //       yBuf = upperY;
  //     }
  //
  //     scaleStrokes(scaleBuffer);
  //   } else {
  //     var delta = getSlideDelta(e);
  //
  //     xBuf = xPos + delta.x;
  //     yBuf = yPos + delta.y;
  //
  //     // MATH SORCERY I ONLY HALF UNDERSTAND
  //     var upperX = w*(scaleBuffer-1)/2;
  //     var lowerX = isLandscape() ? -w*(scaleBuffer-1)/2 : 0; // No clue why this is needed but it fixes landscape so yeah
  //     var upperY = h*(scaleBuffer-1)/(2);
  //     var lowerY = -upperY;
  //
  //     if (xBuf < lowerX) {
  //       xBuf = lowerX;
  //     } else if (xBuf > upperX) {
  //       xBuf = upperX;
  //     }
  //
  //     // Y is different because map is centered vertically I think?
  //     if (yBuf < lowerY) {
  //       yBuf = 0 - h*(scaleBuffer-1)/(2);
  //     } else if (yBuf > upperY) {
  //       yBuf = upperY;
  //     }
  //   }
  //   map.style.transform = `translateX(${xBuf}px) translateY(${yBuf}px) scale(${scaleBuffer})`;
  //
  // });
});
