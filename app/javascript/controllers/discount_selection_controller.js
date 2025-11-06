import { Controller } from "@hotwired/stimulus"

const HIGHLIGHT_CLASS = "ring-2 ring-offset-2 ring-sky-300"

export default class extends Controller {
  static targets = ["row", "summaryName", "summaryDetails"]

  connect() {
    this.clearSummary()
  }

  selectChanged(event) {
    const selectedId = event.target.value
    this.rowTargets.forEach((row) => row.classList.remove(HIGHLIGHT_CLASS))

    if (!selectedId) {
      this.clearSummary()
      return
    }

    const row = this.rowTargets.find((element) => element.dataset.discountId === selectedId)
    if (!row) {
      this.clearSummary()
      return
    }

    row.classList.add(HIGHLIGHT_CLASS)
    row.scrollIntoView({ behavior: "smooth", block: "nearest" })
    this.summaryNameTarget.textContent = row.dataset.discountName || ""
    this.summaryDetailsTarget.textContent = row.dataset.discountDetails || ""
  }

  clearSummary() {
    this.summaryNameTarget.textContent = "割引を選択してください"
    this.summaryDetailsTarget.textContent = ""
  }
}
