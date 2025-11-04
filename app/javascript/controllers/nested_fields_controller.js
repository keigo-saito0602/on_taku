import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]

  add(event) {
    event.preventDefault()
    const template = this.templateTarget
    if (!template) return
    const html = (template.innerHTML || template.textContent || "").trim()
    if (!html) return
    const unique = Date.now().toString()
    const content = html.replace(/NEW_RECORD/g, unique)
    const wrapper = document.createElement("div")
    wrapper.innerHTML = content
    const element = wrapper.firstElementChild
    if (!element) return
    this.containerTarget.appendChild(element)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-fields-target='item']")
    if (!item) return
    const destroyInput = item.querySelector("input[data-nested-fields-destroy]")
    if (destroyInput) {
      destroyInput.value = "1"
      item.classList.add("hidden")
      item.setAttribute("aria-hidden", "true")
    } else {
      item.remove()
    }
  }
}
