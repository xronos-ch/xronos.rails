import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static targets = ["select", "contextId", "name", "fields", "help"]

  connect() {
    this.select = new TomSelect(this.selectTarget, {
      maxItems: 1,
      plugins: ["dropdown_input"],
      allowEmptyOption: true,
      createOnBlur: false,
      persist: true,
      placeholder: "Search or enter a new name",
      create: input => {
        const name = input.trim()
        return name ? { value: `new:${name}`, text: name } : false
      },
      createFilter: input => {
        const name = input.trim().toLowerCase()
        return name && !Object.values(this.select.options).some(option => option.text.toLowerCase() === name)
      },
      render: {
        option_create: (data, escape) => `<div class="create">Create “${escape(data.input.trim())}”</div>`
      },
      onChange: () => this.update()
    })
    this.update()
  }

  disconnect() {
    this.select?.destroy()
  }

  update() {
    const value = this.selectTarget.value
    const isNew = value.startsWith("new:")
    this.contextIdTarget.value = isNew ? "" : value
    this.nameTarget.value = isNew ? value.slice(4) : ""
    this.fieldsTarget.disabled = !isNew
    this.fieldsTarget.hidden = !isNew
    this.helpTarget.textContent = isNew
      ? "New context · will be created when you save."
      : "Optional: select or add a more specific context."
  }
}
