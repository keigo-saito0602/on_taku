import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["eventFee", "drinkFee", "total"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    const eventFee = parseInt(this.eventFeeTarget.value || "0", 10)
    const drinkFee = parseInt(this.drinkFeeTarget.value || "0", 10)
    const total = eventFee + drinkFee
    this.totalTarget.textContent = total.toLocaleString()
  }
}
