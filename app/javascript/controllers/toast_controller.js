import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = { duration: { type: Number, default: 5000 } }

  connect() {
    this.timer = setTimeout(() => this.dismiss(), this.durationValue)
  }

  dismiss() {
    clearTimeout(this.timer)
    this.containerTarget.classList.add("opacity-0", "translate-y-2")
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
