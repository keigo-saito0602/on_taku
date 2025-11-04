import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startTimeInput", "endTimeInput", "template"]

  applyTemplate() {
    if (!this.hasTemplateTarget) return
    const minutes = parseInt(this.templateTarget.value || "0", 10)
    if (!minutes) return

    const startMinutes = this.parseMinutes(this.startTimeInputTarget.value)
    if (startMinutes === null) return

    const endMinutes = startMinutes + minutes
    if (endMinutes > 24 * 60) return

    const endValue = this.formatMinutes(endMinutes)
    this.endTimeInputTarget.value = endValue
  }

  startChanged() {
    this.templateTarget.value = ""
  }

  endChanged() {
    // no-op but kept for consistency with form data attributes
  }

  parseMinutes(value) {
    if (!value || !/^[0-2]\d:[0-5]\d$/.test(value)) return null
    const [hours, minutes] = value.split(":").map(Number)
    return hours * 60 + minutes
  }

  formatMinutes(total) {
    const clamped = Math.max(0, Math.min(total, 24 * 60))
    const hours = Math.floor(clamped / 60)
    const minutes = clamped % 60
    return `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}`
  }
}
