import { Controller } from "@hotwired/stimulus"

const POLL_INTERVAL = 250
const MINIMUM_DISPLAY_TIME = 600
const HEARTBEAT_INTERVAL = 5000
const HEARTBEAT_TIMEOUT = 3000
const MAX_HEARTBEAT_FAILURES = 3
const MAX_WAIT_MINUTES = 5
const MAX_WAIT = MAX_WAIT_MINUTES * 60 * 1000

export default class extends Controller {
  start(event) {
    if (this.pending) {
      event.preventDefault()
      return
    }

    // Keep Bootstrap from closing the dropdown that contains this link.
    event.stopPropagation()
    this.pending = true
    this.clearFeedback()
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
    this.heartbeatFailures = 0
    this.heartbeatPending = false
    this.heartbeatTimer = window.setInterval(() => this.checkConnection(), HEARTBEAT_INTERVAL)
    this.timeoutTimer = window.setTimeout(() => this.handleTimeout(), MAX_WAIT)
    this.checkConnection()
  }

  connect() {
    this.beforeCache = () => {
      this.finish()
      this.clearFeedback()
    }
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
    const cookie = document.cookie
      .split("; ")
      .find(cookie => cookie.startsWith(`${this.cookieName}=`))

    if (!cookie || Date.now() - this.startedAt < MINIMUM_DISPLAY_TIME) return

    const result = cookie.slice(this.cookieName.length + 1)
    this.clearResponseCookie()

    if (result === "ready") {
      this.finish()
      return
    }

    const status = result.match(/^error-(\d{3})$/)?.[1]
    this.finish(status ? `The download request failed (HTTP ${status}).` : "The download request failed.")
  }

  async checkConnection() {
    if (!this.pending || this.heartbeatPending) return

    this.heartbeatPending = true
    this.heartbeatController = new AbortController()
    this.heartbeatTimeout = window.setTimeout(
      () => this.heartbeatController?.abort(),
      HEARTBEAT_TIMEOUT
    )

    try {
      const response = await fetch("/up", {
        cache: "no-store",
        credentials: "same-origin",
        signal: this.heartbeatController.signal
      })

      if (!response.ok) throw new Error(`Health check returned ${response.status}`)
      this.heartbeatFailures = 0
    } catch {
      this.heartbeatFailures += 1
      if (this.heartbeatFailures >= MAX_HEARTBEAT_FAILURES) {
        this.finish("The server is not responding. The download may not have completed.")
      }
    } finally {
      window.clearTimeout(this.heartbeatTimeout)
      this.heartbeatTimeout = null
      this.heartbeatController = null
      this.heartbeatPending = false
    }
  }

  handleTimeout() {
    this.checkReady()
    if (!this.pending) return

    this.finish(
      `No response after ${MAX_WAIT_MINUTES} minutes. The export may still be running; check before retrying.`,
      "warning"
    )
  }

  finish(message = null, messageType = "danger") {
    if (!this.pending) return

    window.clearInterval(this.pollTimer)
    window.clearInterval(this.heartbeatTimer)
    window.clearTimeout(this.timeoutTimer)
    window.clearTimeout(this.heartbeatTimeout)
    this.heartbeatController?.abort()
    this.element.setAttribute("href", this.originalHref)
    this.element.innerHTML = this.originalContent
    this.element.removeAttribute("aria-disabled")
    this.element.removeAttribute("aria-busy")
    this.element.classList.remove("disabled")
    this.pending = false

    if (message) {
      this.showFeedback(message, messageType)
      return
    }

    const dropdown = this.element.closest(".dropdown, .btn-group")
    const menu = this.element.closest(".dropdown-menu")
    const toggle = dropdown?.querySelector('[data-bs-toggle="dropdown"]')
    if (menu?.classList.contains("show")) toggle?.click()
  }

  clearResponseCookie() {
    document.cookie = `${this.cookieName}=; Max-Age=0; path=/; SameSite=Lax`
  }

  clearFeedback() {
    const feedback = this.element.nextElementSibling
    if (feedback?.matches("[data-download-feedback]")) feedback.remove()
  }

  showFeedback(message, messageType) {
    this.clearFeedback()

    const feedback = document.createElement("span")
    feedback.dataset.downloadFeedback = "true"
    feedback.className = `small text-${messageType} ms-2`
    feedback.setAttribute("role", messageType === "danger" ? "alert" : "status")
    feedback.textContent = message
    this.element.insertAdjacentElement("afterend", feedback)
  }
}
