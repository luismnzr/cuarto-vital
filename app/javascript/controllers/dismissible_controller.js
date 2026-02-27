import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  dismiss() {
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")
    setTimeout(() => this.element.remove(), 300)
  }
}
