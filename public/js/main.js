let tap = null; // To determine whether we have a single or double tap
let journey = []; // Keeps track of the countries selected to be sent to the server
const yScale = 1.4125;

// Checks if we have less than the maximum number of countries
const tooManyCountries = () => {
  let realList = journey.filter((c) => {
    return !(c === null)
  })

  return !(realList.length < 9)
}

// Returns the last country, skipping null entries
const lastCountry = () => {
  let realList = journey.filter((c) => {
    return !(c === null)
  })

  return realList[realList.length-1]
}

// Helper to add a country to the journey array and list
const addCountry = (c, flag) => {
  // Make sure we don't add too many countries
  if (tooManyCountries()) {
    return
  }

  // Style the country
  c.classList.add('selected');
  // Add it but only if it isn't already the latest point in the journey
  if (lastCountry() !== c.id) {
    // Add to journey array
    journey.push(c.id);

    // Find list
    let countryList = document.getElementById('country-list');
    // Create new item
    let item = document.createElement('li');
    let cont = document.createElement('div');
    item.appendChild(cont);
    let t = document.createTextNode(c.id);
    cont.appendChild(t);

    // Append flag if there is one
    if (flag) {
      let flagEl = document.createElement('img');
      flagEl.classList.add('flag');
      flagEl.src = `/static/img/flags/${flag}`
      cont.appendChild(flagEl);
    }

    // Give item an index
    item.dataset.i = journey.length-1;
    // Event listener to allow for removal
    item.addEventListener('click', (e) => {
      e.preventDefault();
      remCountry(item, item.dataset.i);
    })

    // add item to list
    countryList.appendChild(item);
  }
}

// Helper to undo last country added
const popCountry = () => {
  let country = journey.pop();
  if (!journey.includes(country) && country !== null) {
    document.getElementById(country).classList.remove('selected');
  }

  let countryList = document.getElementById('country-list');
  countryList.removeChild(countryList.lastChild);
}

// Helper to remove specific countries from journey
const remCountry = (elt, i) => {
  let country = elt.textContent;
  journey[i] = null;
  if (!journey.includes(country)) {
    document.getElementById(country).classList.remove('selected');
  }

  let countryList = document.getElementById('country-list');
  countryList.removeChild(elt);
}

// Loads country + flag data from our JSON file
const loadData = (cb) => {
  fetch('/static/countries.json')
    .then((res) => {
      return res.json();
    })
    .then((data) => {
      cb(data);
    })
}

// Binds mouse and touch events to country regions. Passes flag data through for the country list.
const addCountryEvents = (country, tag, flag) => {
  // // === Desktop/debug events ===
  // // 'click' <=> double tap
  // country.addEventListener('click', (e) => {
  //   console.log(country.id);
  //   addCountry(country, flag);
  // });
  // // 'mouseenter' <=> 'touchstart'
  // country.addEventListener('mouseenter', (e) => {
  //   tag.style.left = `${e.clientX}px`;
  //   tag.style.top = `${e.clientY}px`;
  //   tag.classList.remove('hidden');
  // });
  // // 'mouseleave' <=> 'touchend'
  // country.addEventListener('mouseleave', (e) => {
  //   tag.classList.add('hidden');
  // });

  // === Mobile/final events ===
  // 'touchstart' handles single touch (show tag) and double tap (select country)
  country.addEventListener('touchstart', (e) => {
    // If we haven't tapped recently or we are tapping with several fingers, reset the counter
    if (!tap || e.touches.length > 1) {
      tap = setTimeout(() => {
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
     e.preventDefault();

      let touch = e.touches[0];
      tag.style.left = `${touch.clientX - 150}px`;
      tag.style.top = `${touch.clientY - 150}px`;
      tag.classList.remove('hidden');
    } else {
      tag.classList.add('hidden');
    }
  });

  // 'touchend' handles the end of a touch (hide tag)
  country.addEventListener('touchend', (e) => {
    // tag.classList.add('hidden');
    clearTags();
  });

}

// Helper to convert from (longitude, latitude) to normalized SVG (x,y) coordinates
const earthToSvg = (_lon, _lat) => {
  let lon = parseFloat(_lon);
  let lat = parseFloat(_lat);

  let tx = (lon + 180) / 360;
  let ty = 1 - (lat + 85) / 170; // Latitudes close to 90 are truncated

  return {
    x: tx,
    y: ty
  };
}

const tagCountries = (data) => {
  // Get all our country shapes
  let countries = document.getElementsByTagName('path');

  // For convenience, let's take the names into a separate array
  let countryNames = [];
  for (let i = 0; i < countries.length; ++i) {
    countryNames.push(countries[i].id);
  }

  // Filter our data (flag + coordinates) based on actual matches with our map
  let matches = data.filter((entry) => {
    return countryNames.includes(entry.name);
  })

  // Build a match object for easy dictionary access
  let matchObj = {};
  for (let i = 0; i < matches.length; ++i) {
    let match = matches[i];
    let entry = {
      lat: match.latitude,
      lon: match.longitude,
      flag: match.flag_128
    };

    matchObj[match.name] = entry;
  }

  // Iterate through countries to set them all up
  for (let i = 0; i < countries.length; ++i) {
    // Pick a country
    let country = countries[i];

    // Kill Antarctica soz
    if (country.id === "Antarctica") {
      let group = country.parentNode;
      group.removeChild(country);
      continue;
    }

    // Add coordinate data
    let countryData = matchObj[country.id];
    let flag = undefined;
    // A few regions aren't in the dataset so we check to skip them
    if (countryData) {
      country.dataset.lat = countryData.lat;
      country.dataset.lon = countryData.lon;
      flag = countryData.flag;
    }

    // Create a tag for it
    let tag = document.createElement('div');
    tag.classList.add('hidden', 'tag-bg', 'tag');
    let p = document.createElement('p');
    p.classList.add('tag-text');
    let txt = document.createTextNode(country.id);
    p.appendChild(txt);
    tag.appendChild(p);
    document.body.appendChild(tag);

    // Bind events to the country shape
    addCountryEvents(country, tag, flag);
  }
}

// POSTs the journey data to the server to be recorded and displayed
const postJourney = () => {
  // Remove leftover null elements from our journey
  let cleanJourney = journey.filter((entry) => {
    return entry !== null;
  }).map((entry) => {
    let country = document.getElementById(entry);
    let coord = earthToSvg(country.dataset.lon, country.dataset.lat);
    return {
      name: entry,
      lon: country.dataset.lon,
      lat: country.dataset.lat
    }
  });
  // Abort if data is empty!
  if (cleanJourney.length === 0) {
    return;
  }
  // POST data to the server
  let data = JSON.stringify(cleanJourney);
  fetch('/api/submit', {
    body: data,
    headers: {
      'content-type': 'application/json'
    },
    method: 'POST'
  }).then((res) => {
    // Make sure our submission made it through
    if (res.ok) {
      // Clear our journey once we are done
      while (journey.length > 0) {
        // We use popCountry to ensure the list and map get cleared as well
        popCountry();
      }
    }
  })
}

const getPinch = (e) => {
  e.preventDefault();
  let x1 = e.touches.item(0).screenX;
  let y1 = e.touches.item(0).screenY;
  let x2 = e.touches.item(1).screenX;
  let y2 = e.touches.item(1).screenY;
  let dx = x2 - x1;
  let dy = y2 - y1;

  let px1 = touchBuffer[0].screenX;
  let py1 = touchBuffer[0].screenY;
  let px2 = touchBuffer[1].screenX;
  let py2 = touchBuffer[1].screenY;
  let pdx = px2 -px1;
  let pdy = py2 - py1;

  let dist = Math.sqrt(dx*dx + dy*dy);
  let pdist = Math.sqrt(pdx*pdx + pdy*pdy);

  return {
    scale: dist/pdist,
    x: (x1 + x2) / 2,
    y: (y1 + y2) / 2
  };
}

const getSlideDelta = (e) => {
  // e.preventDefault();

  let x = e.touches.item(0).screenX;
  let y = e.touches.item(0).screenY;
  let px = touchBuffer[0].screenX;
  let py = touchBuffer[0].screenY;

  let dx = x - px;
  let dy = y - py;

  return {
    x: dx,
    y: dy
  };
}

let touchBuffer = [];
let mapScale = 1;
let scaleBuffer;
let pinchCenter= {
  x: 1, y: 1,
  xp: 0, yp: 0
}
let xPos = 0, yPos = 0;
let xBuf = 0, yBuf = 0;
let w = 0, h = 0;

const resetView = () => {
  mapScale = 1;
  scaleBuffer = 0;
  xPos = 0;
  xBuf = 0;
  yPos = 0;
  yBuf = 0;

  let map = document.getElementById('map-container')
    map.style.transform = `translateX(${xPos}px) translateY(${yPos}px) scale(${mapScale})`;
}

const scaleStrokes = (scale) => {
  let countries = document.getElementsByTagName('path');
  let countryList = Array.from(countries);

  countryList.forEach((country) => {
    country.style.strokeWidth = 1/scale;
  });
}

// Because events are weird so let's brute force this thing
const clearTags = () => {
  let tags = document.getElementsByClassName('tag')
  let tagList = Array.from(tags)

  tagList.forEach((tag) => {
    tag.classList.add('hidden')
  })
}

document.addEventListener('DOMContentLoaded', () => {
  loadData(tagCountries);

  let map = document.getElementById('map-container')

  let svg = map.firstChild;

  w = map.clientWidth;
  h = map.clientHeight;

  // Detect oreintation change to keep scroll magic working
  window.addEventListener('orientationchange', (e) => {
    w = map.clientWidth;
    h = map.clientHeight;
  })

  // Disable pinch-zooming on country list
  let listArea = document.getElementById('list-container')
  listArea.addEventListener('touchmove', (e) => {
    if (e.touches.length >= 2) {
      e.preventDefault()
    }
  })

  map.addEventListener('touchstart', (e) => {
    touchBuffer = [];
    for (let i = 0; i < e.touches.length; ++i) {
      touchBuffer.push(e.touches[i]);
    }

    // let t = e.touches[0];
    // console.log(`(${t.clientX}, ${t.clientY})`)
    if (e.touches.length === 2) {
      let pinch = getPinch(e);
      pinchCenter = {
        x: pinch.x,
        y: pinch.y
      }
    }
  })
  map.addEventListener('touchend', (e) => {
    mapScale = scaleBuffer;
    if (e.touches.length === 0) {
      clearTags();
      xPos = xBuf;
      yPos = yBuf;
      touchBuffer = [];
    }
  })
  map.addEventListener('touchmove', (e) => {
    if (e.touches.length >= 2) {
      let pinch = getPinch(e);
      let scale = pinch.scale;
      scaleBuffer = mapScale*scale;

      scaleBuffer = scaleBuffer > 1 ? scaleBuffer : 1;

      let dx = pinch.x - pinchCenter.x;
      let dy = pinch.y - pinchCenter.y;

      xBuf = xPos + dx;
      yBuf = yPos + dy;

      // xBuf = xPos-pinchCenter.x
      // yBuf = (pinch.y)*(scaleBuffer-1)/2;

      // MATH SORCERY I ONLY HALF UNDERSTAND
      let upperX = w*(scaleBuffer-1)/2;
      let upperY = h*(scaleBuffer-1)/(2);
      let lowerY = -upperY;

      if (xBuf < 0) {
        xBuf = 0;
      } else if (xBuf > upperX) {
        xBuf = upperX;
      }

      // Y is different because map is centered vertically I think?
      if (yBuf < lowerY) {
        yBuf = 0 - h*(scaleBuffer-1)/(2);
      } else if (yBuf > upperY) {
        yBuf = upperY;
      }

      scaleStrokes(scaleBuffer);
    } else {
      let delta = getSlideDelta(e);

      xBuf = xPos + delta.x;
      yBuf = yPos + delta.y;

      // MATH SORCERY I ONLY HALF UNDERSTAND
      let upperX = w*(scaleBuffer-1)/2;
      let upperY = h*(scaleBuffer-1)/(2);
      let lowerY = -upperY;

      if (xBuf < 0) {
        xBuf = 0;
      } else if (xBuf > upperX) {
        xBuf = upperX;
      }

      // Y is different because map is centered vertically I think?
      if (yBuf < lowerY) {
        yBuf = 0 - h*(scaleBuffer-1)/(2);
      } else if (yBuf > upperY) {
        yBuf = upperY;
      }
    }
    map.style.transform = `translateX(${xBuf}px) translateY(${yBuf}px) scale(${scaleBuffer})`;

  })
})
