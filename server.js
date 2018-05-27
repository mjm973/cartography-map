const express = require('express')
const favicon = require('serve-favicon');
const path = require('path');
const app = express();

const port = process.env.PORT || 4242;

app.set('view engine', 'pug');

app.use('/static', express.static(path.join(__dirname, 'public')))
app.use('/views', express.static(path.join(__dirname, 'views')))

app.get('/', (cReq, cRes) => {
  cRes.render('index');
});

const server = app.listen(port, () => console.log(`Server listening on port ${port}...`))

const io = require('socket.io').listen(server);


io.on('connection', (socket) => {

})
