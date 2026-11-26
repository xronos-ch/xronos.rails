import MapController from "./controllers/map_controller"

function registerMap() {
  window.Stimulus.register("map", MapController)
}

if (window.Stimulus) {
  registerMap()
} else {
  document.addEventListener("DOMContentLoaded", registerMap, { once: true })
}
