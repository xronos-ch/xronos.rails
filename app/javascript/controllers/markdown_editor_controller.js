import { Controller } from "@hotwired/stimulus"

import EasyMDE from "easymde" // https://github.com/Ionaru/easy-markdown-editor

// Connects to data-controller="markdown-editor"
export default class extends Controller {
	// this approach suggested by https://www.betterstimulus.com/integrating-libraries/lifecycle.html
	static targets = [ "field" ]

  connect() {
		this.editor = new EasyMDE({
			element: this.fieldTarget,
			autoDownloadFontAwesome: false
		})
  }

	disconnect() {
		this.editor.toTextArea()
	}
}
