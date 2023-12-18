import { Controller } from "@hotwired/stimulus"

import EasyMDE from "easymde" // https://github.com/Ionaru/easy-markdown-editor
import "easymde/dist/easymde.min.css"

// Connects to data-controller="markdown-editor"
export default class extends Controller {
	// this approach suggested by https://www.betterstimulus.com/integrating-libraries/lifecycle.html
	static targets = [ "field" ]

  connect() {
		this.editor = new EasyMDE({
			element: this.fieldTarget,
			autoDownloadFontAwesome: false,
			iconClassMap: {
				'bold': 'bi-type-bold',
				'italic': 'bi-type-italic',
				'strikethrough': 'bi-type-strikethrough',
				'heading': 'bi-hash',
				'heading-smaller': 'header-smaller',
				'heading-bigger': 'header-bigger',
				'heading-1': 'bi-type-h1',
				'heading-2': 'bi-type-h2',
				'heading-3': 'bi-type-h3',
				'code': 'bi-braces',
				'quote': 'bi-quote',
				'ordered-list': 'bi-list-ol',
				'unordered-list': 'bi-list-ul',
				'clean-block': 'bi-eraser',
				'link': 'bi-link',
				'image': 'bi-image',
				'upload-image': 'bi-image',
				'table': 'bi-table',
				'horizontal-rule': 'bi-hr',
				'preview': 'bi-eye',
				'side-by-side': 'bi-layout-split',
				'fullscreen': 'bi-fullscreen',
				'guide': 'bi-question-circle',
				'undo': 'bi-arrow-counterclockwise',
				'redo': 'bi-arrow-clockwise',
			}
		})
  }

	disconnect() {
		this.editor.toTextArea()
	}
}
