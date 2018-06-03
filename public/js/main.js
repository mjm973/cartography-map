let tap = null; // To determine whether we have a single or double tap
let journey = []; // Keeps track of the countries selected to be sent to the server

// Helper to add a country to the journey array and list
let addCountry = (c, flag) => {
  // Style the country
  c.classList.add('selected');
  // Add it but only if it isn't already the latest point in the journey
  if (journey[journey.length-1] !== c.id) {
    // Add to journey array
    journey.push(c.id);

    // Find list
    let countryList = document.getElementById('country-list');
    // Create new item
    let item = document.createElement('li');
    let t = document.createTextNode(c.id);
    item.appendChild(t);

    // Append flag if there is one
    if (flag) {
      let flagEl = document.createElement('img');
      flagEl.classList.add('flag');
      flagEl.src = `/static/img/flags/${flag}`
      item.appendChild(flagEl);
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
let popCountry = () => {
  let country = journey.pop();
  if (!journey.includes(country)) {
    document.getElementById(country).classList.remove('selected');
  }

  let countryList = document.getElementById('country-list');
  countryList.removeChild(countryList.lastChild);
}

// Helper to remove specific countries from journey
let remCountry = (elt, i) => {
  let country = elt.textContent;
  journey[i] = null;
  if (!journey.includes(country)) {
    document.getElementById(country).classList.remove('selected');
  }

  let countryList = document.getElementById('country-list');
  countryList.removeChild(elt);
}

// Loads country + flag data from our JSON file
let loadData = (cb) => {
  fetch('/static/countries.json')
    .then((res) => {
      return res.json();
    })
    .then((data) => {
      cb(data);
    })
}

// Binds mouse and touch events to country regions. Passes flag data through for the country list.
let addCountryEvents = (country, tag, flag) => {
  // === Desktop/debug events ===
  // 'click' <=> double tap
  country.addEventListener('click', (e) => {
    console.log(country.id);
    addCountry(country, flag);
  });
  // 'mouseenter' <=> 'touchstart'
  country.addEventListener('mouseenter', (e) => {
    tag.style.left = `${e.clientX}px`;
    tag.style.top = `${e.clientY}px`;
    tag.classList.remove('hidden');
  });
  // 'mouseleave' <=> 'touchend'
  country.addEventListener('mouseleave', (e) => {
    tag.classList.add('hidden');
  });

  // === Mobile/final events ===
  // 'touchstart' handles single touch (show tag) and double tap (select country)
  country.addEventListener('touchstart', (e) => {
    if (!tap || e.touches.length > 1) {
      tap = setTimeout(() => {
        tap = null;
      }, 300);
    } else {
      clearTimeout(tap);
      tap = null;

      e.preventDefault();
      addCountry(country, flag);
    }

    let touch = e.touches[0];
    tag.style.left = `${touch.clientX}px`;
    tag.style.top = `${touch.clientY}px`;
    tag.classList.remove('hidden');
  });
  // 'touchend' handles the end of a touch (hide tag)
  country.addEventListener('touchend', (e) => {
    tag.classList.add('hidden');
  });
}

// Helper to convert from (longitude, latitude) to SVG (x,y) coordinates
let earthToSvg = (_lon, _lat) => {
  console.log(typeof _lon, typeof _lat);
  let lon = parseFloat(_lon);
  let lat = parseFloat(_lat);
  console.log(typeof lon, typeof lat);

  let tx = (lon + 180) / 360;
  let ty = 1 - (lat + 90) / 180;
  let mapSvg = document.getElementById('map-svg');
  let w = mapSvg.getAttribute('width');
  let h = mapSvg.getAttribute('height');

  return {
    x: parseFloat(w)*tx,
    y: parseFloat(h)*ty
  };
}

let tagCountries = (data) => {
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
    tag.classList.add('hidden', 'tag-bg');
    let p = document.createElement('p');
    p.classList.add('tag-text');
    let txt = document.createTextNode(country.id);
    p.appendChild(txt);
    tag.appendChild(p);
    document.getElementById('map-container').appendChild(tag);

    // Bind events to the country shape
    addCountryEvents(country, tag, flag);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  loadData(tagCountries);
})
