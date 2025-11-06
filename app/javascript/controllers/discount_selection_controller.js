import { Controller } from "@hotwired/stimulus"

const HIGHLIGHT_CLASS = "ring-2 ring-offset-2 ring-sky-300"
const formatter = new Intl.NumberFormat("ja-JP", {
  style: "currency",
  currency: "JPY",
  maximumFractionDigits: 0
})

export default class extends Controller {
  static targets = [
    "row",
    "summaryName",
    "summaryDetails",
    "priceOriginal",
    "priceDiscounted",
    "emptyState",
    "select"
  ]

  static values = {
    basePrice: { type: Number, default: 0 }
  }

  connect() {
    this.updateDisplay(this.selectTarget?.value || "")
  }

  selectChanged(event) {
    this.updateDisplay(event.target.value)
  }

  updateDisplay(selectedId) {
    this.rowTargets.forEach((row) => row.classList.remove(HIGHLIGHT_CLASS))

    const row = this.rowTargets.find((element) => element.dataset.discountId === selectedId)

    if (!row) {
      this.clearSummary()
      this.toggleEmptyState(true)
      this.updatePrice(this.basePriceValue)
      return
    }

    row.classList.add(HIGHLIGHT_CLASS)
    row.scrollIntoView({ behavior: "smooth", block: "nearest" })
    this.summaryNameTarget.textContent = row.dataset.discountName || ""
    this.summaryDetailsTarget.textContent = row.dataset.discountDetails || ""
    this.toggleEmptyState(false)
    this.rowTargets.forEach((element) => {
      element.classList.toggle("hidden", element !== row)
    })
    this.updatePrice(this.calculateDiscountedPrice(row))
  }

  clearSummary() {
    this.summaryNameTarget.textContent = "割引を選択してください"
    this.summaryDetailsTarget.textContent = ""
    this.rowTargets.forEach((row) => row.classList.add("hidden"))
  }

  toggleEmptyState(show) {
    if (!this.hasEmptyStateTarget) return
    this.emptyStateTarget.classList.toggle("hidden", !show)
  }

  updatePrice(amount) {
    if (this.hasPriceOriginalTarget) {
      this.priceOriginalTarget.textContent = formatter.format(this.basePriceValue)
    }
    if (this.hasPriceDiscountedTarget) {
      this.priceDiscountedTarget.textContent = formatter.format(Math.max(0, Math.floor(amount)))
    }
  }

  calculateDiscountedPrice(row) {
    const kind = row.dataset.discountKind
    const value = Number(row.dataset.discountValue || 0)
    const base = this.basePriceValue

    if (!kind) return base

    if (kind === "percentage") {
      return Math.max(0, Math.floor((base * (100 - value)) / 100))
    }

    if (kind === "fixed") {
      return Math.max(0, base - value)
    }

    return base
  }

  async destroy(event) {
    event.preventDefault()
    const button = event.currentTarget
    const discountName = button.dataset.discountSelectionNameParam || "割引"
    if (!window.confirm(`割引「${discountName}」を削除しますか？`)) return

    const url = button.dataset.discountSelectionUrlParam
    if (!url) return

    try {
      const response = await fetch(url, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": this.csrfToken(),
          Accept: "text/vnd.turbo-stream.html, text/html, application/json"
        }
      })
      if (!response.ok) throw new Error("Failed to delete discount")
      this.removeRow(button.closest("[data-discount-id]"))
    } catch (error) {
      console.error(error)
      alert("割引を削除できませんでした。")
    }
  }

  removeRow(row) {
    if (!row) return
    const removedId = row.dataset.discountId
    row.remove()

    if (this.hasSelectTarget) {
      const options = Array.from(this.selectTarget.options || [])
      const index = options.findIndex((option) => option.value === removedId)
      if (index >= 0) {
        this.selectTarget.remove(index)
      }
    }

    if (this.selectTarget && this.selectTarget.value === removedId) {
      this.selectTarget.value = ""
    }

    this.updateDisplay(this.selectTarget?.value || "")
  }

  csrfToken() {
    const element = document.querySelector('meta[name="csrf-token"]')
    return element ? element.content : ""
  }
}
