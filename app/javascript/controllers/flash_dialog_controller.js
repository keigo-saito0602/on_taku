import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    message: String
  }

  connect() {
    if (!this.hasMessageValue || !this.messageValue) return

    const title = this.titleValue?.trim()
    const body = this.messageValue.trim()
    if (!body) return

    const text = title ? `${title}\n${body}` : body
    window.alert(text)
  }
}
