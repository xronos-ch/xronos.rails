import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL = 100
const MINIMUM_DISPLAY_TIME = 600
const MAX_WAIT = 5 * 60 * 1000

export default class extends Controller {
  start(event) {
    if (this.pending) {
      event.preventDefault()
      return
    }

    // Keep Bootstrap from closing the dropdown that contains this link.
    event.stopPropagation()
    this.pending = true
    this.originalHref = this.element.getAttribute("href")
    this.originalContent = this.element.innerHTML
    this.requestId = crypto.randomUUID()
    this.startedAt = Date.now()

    const url = new URL(this.element.href)
    url.searchParams.set("download_request_id", this.requestId)
    this.element.href = url.toString()
    this.element.setAttribute("aria-disabled", "true")
    this.element.setAttribute("aria-busy", "true")
    this.element.classList.add("disabled")
    this.element.append(this.indicator())

    this.cookieName = `xronos_download_${this.requestId}`
    this.pollTimer = window.setInterval(() => this.checkReady(), POLL_INTERVAL)
    this.timeoutTimer = window.setTimeout(() => this.finish(), MAX_WAIT)
  }

  connect() {
    this.beforeCache = () => this.finish()
    document.addEventListener("turbo:before-cache", this.beforeCache)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.beforeCache)
    this.finish()
  }

  indicator() {
    const indicator = document.createElement("span")
    indicator.className = "ms-2"
    indicator.setAttribute("role", "status")

    const spinner = document.createElement("span")
    spinner.className = "spinner-border spinner-border-sm"
    spinner.setAttribute("aria-hidden", "true")

    const label = document.createElement("span")
    label.className = "ms-1"
    label.textContent = "Preparing…"

    indicator.append(spinner, label)
    return indicator
  }

  checkReady() {
    const ready = document.cookie
      .split("; ")
      .some(cookie => cookie === `${this.cookieName}=ready`)

    if (!ready || Date.now() - this.startedAt < MINIMUM_DISPLAY_TIME) return

    document.cookie = `${this.cookieName}=; Max-Age=0; path=/; SameSite=Lax`
    this.finish()
  }

  finish() {
    if (!this.pending) return

    window.clearInterval(this.pollTimer)
    window.clearTimeout(this.timeoutTimer)
    this.element.setAttribute("href", this.originalHref)
    this.element.innerHTML = this.originalContent
    this.element.removeAttribute("aria-disabled")
    this.element.removeAttribute("aria-busy")
    this.element.classList.remove("disabled")
    this.pending = false

    const dropdown = this.element.closest(".dropdown")
    const menu = this.element.closest(".dropdown-menu")
    const toggle = dropdown?.querySelector('[data-bs-toggle="dropdown"]')
    if (menu?.classList.contains("show")) toggle?.click()
  }
}
