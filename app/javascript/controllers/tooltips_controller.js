import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

// Connects to data-controller="tooltips"
export default class extends Controller {
  connect() {
	  new Tooltip(this.element)
  }
}
