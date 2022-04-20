import { Controller } from "@hotwired/stimulus"
import TomSelect      from "tom-select"

export default class extends Controller {
	connect() {
		var settings = {
			maxOptions: null,
		};
		new TomSelect(this.element, settings)
	}
}
