const express = require('express')
const favicon = require('serve-favicon');
const path = require('path');
const app = express();

const port = process.env.PORT || 80;

app.set('view engine', 'pug');

app.use('/static', express.static(path.join(__dirname, 'public')))
app.use('/views', express.static(path.join(__dirname, 'views')))
app.use(express.json())
app.use(express.urlencoded())

// Journey data master object - to keep track of all journeys and re-sync display app if needed
let journeys = [];

// ==== USER ROUTES ====
// Base route: serves the map to the users
app.get('/', (cReq, cRes) => {
  cRes.render('index', {test: 0});
});

// ==== API ROUTES ====
// API submit route: receives journey data from users
app.post('/api/submit', (cReq, cRes) => {
  // Add submitted journey to our master list
  journeys.push(cReq.body)
  console.log(journeys)
  cRes.send('yay')
});

// API sync route: used by the display app to retrieve the full journey data
app.get('/api/sync', (cReq, cRes) => {
  console.log("Sync request received!")
  // Display App expects a 2D array, so we send a nested empy array if journeys is empty
  cRes.json(journeys.length === 0 ? [[]] : journeys)
})

// API update route: used by the display app to retrieved new journey data
app.post('/api/update', (cRes, cReq) => {
  console.log('Update request received!')
  // App should tell us when it last updated
  let count = cReq.body.count
  if (count !== undefined) {
    // We take only the stuff that comes after our last update
    let data = [];
    for (let i = count; i < journeys.length; ++i) {
      data.push(journeys[i]);
    }
    // And we send it!
    cRes.json(data.length === 0 ? [[]] : data)
  }
})

// API download route: downloads the complete journey list held currently by the server
app.get('/api/download', (cReq, cRes) => {
  let jString = JSON.stringify(journeys)
  console.log(jString)
  cRes.render('download', {data: JSON.stringify(journeys)})
})

// API clear route: clears all journeys the server has recorded
// Set up as a GET request for easy access
app.get('/api/clear', (cReq, cRes) => {
  journeys = []
  console.log('Journeys cleared.')
  cRes.redirect('/')
});

// API test route: use this to test the server against crazy conditions
// Serves the usual map client, BUT as a version that spams the server
app.get('/api/test', (cReq, cRes) => {
  cRes.render('index', {test: 1});
})

// API splash route: serves the captive portal's splash page
app.get('/api/splash', (cReq, cRes) => {
  console.log('SPLASH')
  cRes.sendFile(__dirname + '/views/splash.html')
})

// Catch-all: redirects any other requests to the base route
app.get('/*', (cReq, cRes) => {
  cRes.redirect('/');
});

const server = app.listen(port, () => console.log(`Server listening on port ${port}...`))
