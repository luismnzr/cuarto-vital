import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static classes = ["active", "inactive"]

  select(event) {
    const selectedId = event.currentTarget.dataset.tabId

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.tabId === selectedId
      tab.classList.toggle("border-b-2", isActive)
      if (isActive) {
        tab.className = tab.className.replace(/border-transparent text-\[var\(--color-muted-foreground\)\]/g, "border-[var(--color-primary)] text-[var(--color-foreground)]")
        tab.setAttribute("aria-selected", "true")
      } else {
        tab.className = tab.className.replace(/border-\[var\(--color-primary\)\] text-\[var\(--color-foreground\)\]/g, "border-transparent text-[var(--color-muted-foreground)]")
        tab.setAttribute("aria-selected", "false")
      }
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.id !== `panel-${selectedId}`)
    })
  }
}
