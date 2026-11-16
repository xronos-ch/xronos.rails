import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="article-editor"
export default class extends Controller {
	static targets = [ "title", "slug" ]
	slugHasBeenTouched = false

  connect() {
		if (this.slugTarget.value != '') {
			this.slugHasBeenTouched = true
		}
  }

	inputTitle() {
		if (!this.slugHasBeenTouched) {
			this.updateSlug()
		}
	}

	touchSlug() {
		this.slugHasBeenTouched = true
	}

	updateSlug() {
		this.slugTarget.value = this.slugify(this.titleTarget.value)
	}

	// https://www.30secondsofcode.org/js/s/slugify
	slugify(str) {
		return str
			.toLowerCase()
			.trim()
			.replace(/[^\w\s-]/g, '')
			.replace(/[\s_-]+/g, '-')
			.replace(/^-+|-+$/g, '')
	}

}
