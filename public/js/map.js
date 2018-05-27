let mapImg;

let path = [];
let drawing = false;
let fullscreen = false;

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

const postPath = () => {
  let len = path.length;
  if (len < 2) {
    return;
  }

  let query = buildQuery();



  // console.log(query);

  path = [];
}

function preload() {
  mapImg = loadImage('/static/img/map.png');
}

function setup() {
  let w2h = mapImg.width / mapImg.height;
  let h = document.body.clientHeight * 0.9;
  let w = h * w2h;

  console.log(w2h, w, h);

  let cnv = createCanvas(w, h);
  let cnvCont = document.getElementById('map-container');
  cnvCont.appendChild(cnv.elt);

  let btn = createButton('New');
  // btn.class('abs bottom right');
  btn.mousePressed(() => {
    path = [];
  });

  let snd = createButton('Send');
  snd.mousePressed(() => {
    postPath();
  });

  let btnCont = document.getElementById('button-container');
  btnCont.appendChild(btn.elt);
  btnCont.appendChild(snd.elt);

  // frameRate(15);
}

function draw() {
  image(mapImg, 0, 0, width, height);

  stroke(255, 0, 0);
  fill(255);
  strokeWeight(5);

  for (let i = 0; i < path.length - 1; ++i) {
    line(path[i].x, path[i].y, path[i+1].x, path[i+1].y);

    // ellipse(path[i].x, path[i].y, 5, 5);
  }
}

function mousePressed() {
  if (!fullscreen) {
    // toggleFullScreen();
  }

  if (inBounds(mouseX, mouseY)) {
    // console.log('start');
    if (path.length == 0) {
      path.push(createVector(mouseX, mouseY));
    }
    drawing = true;
  }
}

function mouseDragged() {
  if (drawing && touches.length < 2) {
    // console.log('hey');
    path.push(createVector(mouseX, mouseY));
  }
}

function mouseReleased() {
  // console.log('end');
  drawing = false;
  // path = [];
}
