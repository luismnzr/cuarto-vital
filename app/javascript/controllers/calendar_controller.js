import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["weekView", "listView", "weekBtn", "listBtn"]

  connect() {
    this.showWeek()
  }

  showWeek() {
    this.weekViewTarget.classList.remove("hidden")
    this.listViewTarget.classList.add("hidden")
    this.weekBtnTarget.classList.add("active-view")
    this.weekBtnTarget.classList.remove("inactive-view")
    this.listBtnTarget.classList.add("inactive-view")
    this.listBtnTarget.classList.remove("active-view")
  }

  showList() {
    this.listViewTarget.classList.remove("hidden")
    this.weekViewTarget.classList.add("hidden")
    this.listBtnTarget.classList.add("active-view")
    this.listBtnTarget.classList.remove("inactive-view")
    this.weekBtnTarget.classList.add("inactive-view")
    this.weekBtnTarget.classList.remove("active-view")
  }
}
