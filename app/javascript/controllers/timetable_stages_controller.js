import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "stage"]

  connect() {
    this.refresh()
  }

  addStage(event) {
    event.preventDefault()
    const template = this.templateTarget
    if (!template) return

    const html = (template.innerHTML || "").trim()
    if (!html) return

    const unique = Date.now().toString()
    const wrapper = document.createElement("div")
    wrapper.innerHTML = html.replace(/NEW_STAGE/g, unique)
    const stage = wrapper.firstElementChild

    if (!stage) return

    this.containerTarget.appendChild(stage)
    this.refresh()
    stage.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  refresh() {
    const visibleStages = this.stageTargets.filter((stage) => !stage.classList.contains("stage-hidden"))
    visibleStages.forEach((stage, index) => {
      const positionInput = stage.querySelector("input[data-role='stage-position']")
      if (positionInput) positionInput.value = index

      stage.querySelectorAll("[data-role='remove-stage']").forEach((button) => {
        const shouldHide = visibleStages.length <= 1
        button.classList.toggle("hidden", shouldHide)
        button.disabled = shouldHide
      })
    })
  }
}
