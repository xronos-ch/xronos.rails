import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static targets = ["select", "contextId", "name", "startTime", "endTime"]

  static values = { contexts: Object }

  connect() {
    this.currentValue = this.selectTarget.value
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
      onChange: () => { if (this.select) this.change() }
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
  }

  change() {
    this.contextsValue = {
      ...this.contextsValue,
      [this.currentValue]: {
        startTime: this.startTimeTarget.value,
        endTime: this.endTimeTarget.value,
        editable: !this.startTimeTarget.readOnly
      }
    }
    const value = this.selectTarget.value
    const dates = this.contextsValue[value] || { startTime: "", endTime: "", editable: true }
    this.startTimeTarget.value = dates.startTime ?? ""
    this.endTimeTarget.value = dates.endTime ?? ""
    this.startTimeTarget.readOnly = !dates.editable
    this.endTimeTarget.readOnly = !dates.editable
    this.currentValue = value
    this.update()
  }
}
