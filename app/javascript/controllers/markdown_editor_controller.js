import { Controller } from "@hotwired/stimulus"
import EasyMDE from "easymde"

export default class extends Controller {
  static targets = ["field"]
  static values = { toolbar: Array }

  connect() {
    const icons = new Map()
    const toolbar = this.toolbarValue.map(item => {
      if (item === "|") return item

      icons.set(item.icon, item.svg)
      return {
        action: item.action === "guide" ? () => window.open("https://www.markdownguide.org/") : EasyMDE[item.action],
        title: item.title,
        attributes: { "data-icon": item.icon }
      }
    })

    this.editor = new EasyMDE({
      element: this.fieldTarget,
      autoDownloadFontAwesome: false,
      toolbar,
      spellChecker: false
    })

    for (const button of this.editor.gui.toolbar.querySelectorAll("[data-icon]")) {
      button.innerHTML = icons.get(button.dataset.icon)
    }
  }

  disconnect() {
    this.editor.toTextArea()
  }
}
