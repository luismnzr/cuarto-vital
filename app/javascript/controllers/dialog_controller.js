import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template"]
  static values = { id: String }

  open() {
    const content = this.templateTarget.content.cloneNode(true)
    this.dialog = content.firstElementChild
    document.body.appendChild(this.dialog)
    document.body.classList.add("overflow-hidden")
    requestAnimationFrame(() => {
      this.dialog.querySelector("[data-action*='dialog#close']")?.focus()
    })
  }

  close() {
    if (this.dialog) {
      document.body.classList.remove("overflow-hidden")
      this.dialog.remove()
      this.dialog = null
    }
  }

  disconnect() {
    this.close()
  }
}
