// Code from Mozilla to toggle fullscreen
function toggleFullScreen() {
  var doc = window.document;
  var docEl = doc.documentElement;

  var requestFullScreen = docEl.requestFullscreen || docEl.mozRequestFullScreen || docEl.webkitRequestFullScreen || docEl.msRequestFullscreen;
  var cancelFullScreen = doc.exitFullscreen || doc.mozCancelFullScreen || doc.webkitExitFullscreen || doc.msExitFullscreen;

  if(!doc.fullscreenElement && !doc.mozFullScreenElement && !doc.webkitFullscreenElement && !doc.msFullscreenElement) {
    requestFullScreen.call(docEl);
  }
  else {
    cancelFullScreen.call(doc);
  }
}
// end of Mozilla code

document.addEventListener('DOMContentLoaded', function(e) {
  // toggleFullScreen();
  let cnvCont = document.getElementById('map-container');
  cnvCont.addEventListener('touchmove', (e) => {
    if (e.touches.length < 2) {
      e.preventDefault();
    }
  }, false);
});
