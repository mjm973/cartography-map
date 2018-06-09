document.addEventListener('DOMContentLoaded', (e) => {
  // Some code I found in Stack Overflow (https://stackoverflow.com/questions/19721439/download-json-object-as-a-file-from-browser)
  // It makes the browser download JSON data.
  let elem = document.getElementById('download')
  let data = elem.dataset.json
  let dataStr = `data:text/json;charset=utf-8,${encodeURIComponent(elem.dataset.json)}`
  elem.setAttribute('href', dataStr)
  elem.setAttribute('download', 'override.json')
  elem.click()
})
