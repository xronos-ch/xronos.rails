import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="home-hero"
export default class extends Controller {
	connect() {
		this.element.classList.remove("sticky-top")
		this.element.classList.add("fixed-top")
		if (window.scrollY == 0) {
			this.transparent()
		}
	}

	scroll() {
		if (window.scrollY > 0) {
			this.opaque()
		}
		else {
			this.transparent()
		}
	}

	transparent() {
		this.element.classList.add("bg-transparent")
		this.element.classList.remove("shadow")
	}

	opaque() {
		this.element.classList.remove("bg-transparent")
		this.element.classList.add("shadow")
	}
}
