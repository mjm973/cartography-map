const express = require('express')
const favicon = require('serve-favicon');
const path = require('path');
const app = express();

const port = process.env.PORT || 4242;

app.set('view engine', 'pug');

app.use('/static', express.static(path.join(__dirname, 'public')))
app.use('/views', express.static(path.join(__dirname, 'views')))

app.get('/', (cReq, cRes) => {
  cRes.render('index', {master: 0});
});

app.get('/all', (cReq, cRes) => {
  cRes.render('index', {master: 1});
});

const server = app.listen(port, () => console.log(`Server listening on port ${port}...`))

const io = require('socket.io').listen(server);


io.on('connection', (socket) => {
  console.log(`Socket ${socket.id} connected!`)

  socket.on('point', (color, x, y) => {
    console.log(`Socket ${socket.id}: ${x},${y}`)

    io.emit('point', socket.id, color, x, y);
  })

  socket.on('clear', (id) => {
    io.emit('clear', id);
  })
})

// io.on('point', (socket, color, x, y) => {
//   console.log(`Socket ${socket.id}: ${x},${y}`)
// })
