const express = require('express')
const favicon = require('serve-favicon');
const path = require('path');
const app = express();

const port = process.env.PORT || 4242;

app.set('view engine', 'pug');

app.use('/static', express.static(path.join(__dirname, 'public')))
app.use('/views', express.static(path.join(__dirname, 'views')))
app.use(express.json())

// Journey data master object - to keep track of all journeys and re-sync display app if needed
let journeys = [];

// ==== USER ROUTES ====
// Base route: serves the map to the users
app.get('/', (cReq, cRes) => {
  cRes.render('index', {master: 0});
});

// app.get('/all', (cReq, cRes) => {
//   cRes.render('index', {master: 1});
// });

// ==== API ROUTES ====
// API submit route: receives journey data from users
app.post('/api/submit', (cReq, cRes) => {
  // Add submitted journey to our master list
  journeys.push(cReq.body)
  console.log(journeys)
  cRes.send('yay')
});

// API sync route: used by the display app to retrieve the journey data
app.get('/api/sync', (cReq, cRes) => {
  cRes.json(journeys)
})

// API clear route: clears all journeys the server has recorded
// Set up as a GET request for easy access
app.get('/api/clear', (cReq, cRes) => {
  journeys = []
  console.log('Journeys cleared.')
  cRes.redirect('/')
});

// Catch-all: redirects any other requests to the base route
app.get('/*', (cReq, cRes) => {
  cRes.redirect('/');
});

const server = app.listen(port, () => console.log(`Server listening on port ${port}...`))

// const io = require('socket.io').listen(server);
//
//
// io.on('connection', (socket) => {
//   console.log(`Socket ${socket.id} connected!`)
//
//   socket.on('point', (color, x, y) => {
//     console.log(`Socket ${socket.id}: ${x},${y}`)
//
//     io.emit('point', socket.id, color, x, y);
//   })
//
//   socket.on('clear', (id) => {
//     io.emit('clear', id);
//   })
// })

// io.on('point', (socket, color, x, y) => {
//   console.log(`Socket ${socket.id}: ${x},${y}`)
// })
