import { Controller } from "@hotwired/stimulus"
import embed from "vega-embed"

// Connects to data-controller="vega"
export default class extends Controller {
  connect() {
	  window.vegaEmbed = embed
	  window.dispatchEvent(new Event("vega:load"))
  }
}
