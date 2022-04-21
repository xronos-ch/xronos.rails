import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
	  var toast = new Toast(this.element)
	  toast.show()
  }
}
