let mapImg;

let paths = {}
let drawing = false;
let fullscreen = false;

let socket = io.connect();

const inBounds = (x, y) => {
  return !(x < 0 || y < 0 || x > width || y > height);
}

const vec2str = (v) => {
  return `${v.x},${v.y}`;
}

const buildQuery = () => {
  let query = '?';
  for (let i = 0; i < len; ++i) {
    query += `path[]=${vec2str(path[i])}`
    if (i < len -1) {
      query += '&';
    }
  }

  return query;
}

const clearPath = () => {
  paths[socket.id].path = [];

  socket.emit('clear', socket.id);
}

const postPath = () => {
  // let len = path.length;
  // if (len < 2) {
  //   return;
  // }
  //
  // let query = buildQuery();
  //
  // path = [];
}

const addPoint = (_x, _y) => {
  let x = _x/width;
  let y = _y/height;

  paths[socket.id].path.push(createVector(x, y));
  socket.emit('point', paths[socket.id].color, x, y);
}

function preload() {
  mapImg = loadImage('/static/img/world-map.jpg');
}

function setup() {
  let w2h = mapImg.width / mapImg.height;
  let h = document.body.clientHeight * 0.9;
  let w = h * w2h;

  console.log(w2h, w, h);

  let cnv = createCanvas(w, h);
  let cnvCont = document.getElementById('map-container');
  cnvCont.appendChild(cnv.elt);

  let btn = createButton('Clear');
  // btn.class('abs bottom right');
  btn.mousePressed(() => {
    clearPath();
  });

  // let snd = createButton('Send');
  // snd.mousePressed(() => {
  //   postPath();
  // });

  let btnCont = document.getElementById('button-container');
  btnCont.appendChild(btn.elt);
  // btnCont.appendChild(snd.elt);

  // frameRate(15);
}

function draw() {
  image(mapImg, 0, 0, width, height);

  strokeWeight(5);

  for (let p in paths) {
    let path = paths[p].path;
    let col = paths[p].color;

    stroke(col);
    fill(col);

    for (let i = 0; i < path.length - 1; ++i) {
      line(path[i].x*width, path[i].y*height, path[i+1].x*width, path[i+1].y*height);
    }
  }

  // for (let i = 0; i < path.length - 1; ++i) {
  //   line(path[i].x, path[i].y, path[i+1].x, path[i+1].y);
  //
  //   // ellipse(path[i].x, path[i].y, 5, 5);
  // }
}

function mousePressed() {
  if (!fullscreen) {
    // toggleFullScreen();
  }

  if (paths[socket.id] === undefined) {
    paths[socket.id] = {color: [random(255), random(255), random(255)], path: []};
  }

  if (inBounds(mouseX, mouseY)) {
    // console.log('start');
    if (paths[socket.id].path.length == 0 && touches.length < 2) {
      addPoint(mouseX, mouseY);
    }
    drawing = true;
  }
}

function mouseDragged() {
  if (drawing && touches.length < 2
    && inBounds(mouseX, mouseY)) {
    // console.log('hey');
    addPoint(mouseX, mouseY);
  }
}

function mouseReleased() {
  // console.log('end');
  drawing = false;
  // path = [];
}

document.addEventListener('DOMContentLoaded', function(e) {
  // toggleFullScreen();
  let cnvCont = document.getElementById('map-container');
  cnvCont.addEventListener('touchmove', (e) => {
    if (e.touches.length < 2) {
      e.preventDefault();
    }
  }, false);

  let master = document.getElementById('data').dataset.master === '1';
  console.log(master ? 'is master' : 'rekt');

  if (master) {
    socket.on('point', (id, color, x, y) => {
      if (id === socket.id) {
        return;
      }

      console.log(`point! ${id} at ${x},${y}`);

      if (paths[id] === undefined) {
        paths[id] = {color: color, path: []};
      }

      paths[id].path.push(createVector(x, y));
    })

    socket.on('clear', (id) => {
      if (paths[id] !== undefined) {
        paths[id].path = [];
      }
    });
  }
  //
  // console.log(socket);
  // paths[socket.id] = {color: [255, 0, 0], path: []};
  // console.log(paths);
});
