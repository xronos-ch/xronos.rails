import L from "leaflet"
import "leaflet-providers"

export function createBaseMaps(cartoApiKey) {
  const cartoOptions = { apikey: cartoApiKey }

  return {
    Map: L.tileLayer.provider("CartoDB.PositronNoLabels", cartoOptions),
    "Map with labels": L.tileLayer.provider("CartoDB.Positron", cartoOptions),
    Imagery: L.tileLayer.provider("Esri.WorldImagery")
  }
}
