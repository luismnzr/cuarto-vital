import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { deadline: String }
  static targets = ["display"]

  connect() {
    this.update()
    this.timer = setInterval(() => this.update(), 1000)
  }

  update() {
    const deadline = new Date(this.deadlineValue)
    const now = new Date()
    const diff = deadline - now

    if (diff <= 0) {
      this.displayTarget.textContent = "Now"
      clearInterval(this.timer)
      return
    }

    const hours = Math.floor(diff / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((diff % (1000 * 60)) / 1000)

    if (hours > 24) {
      const days = Math.floor(hours / 24)
      this.displayTarget.textContent = `${days}d ${hours % 24}h`
    } else if (hours > 0) {
      this.displayTarget.textContent = `${hours}h ${minutes}m`
    } else {
      this.displayTarget.textContent = `${minutes}m ${seconds}s`
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
