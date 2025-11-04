import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["kindSelect", "membersSection"]
  static values = { memberKinds: Array }

  connect() {
    this.toggleMembersSection()
  }

  kindChanged() {
    this.toggleMembersSection()
  }

  toggleMembersSection() {
    if (!this.hasMembersSectionTarget || !this.hasKindSelectTarget) return
    const value = this.kindSelectTarget.value
    const visibleKinds = this.memberKindsValue?.length ? this.memberKindsValue : ["band", "unit"]
    const shouldShow = visibleKinds.includes(value)
    this.membersSectionTarget.classList.toggle("hidden", !shouldShow)
    this.membersSectionTarget.classList.toggle("opacity-50", !shouldShow)
    const inputs = this.membersSectionTarget.querySelectorAll("input, select, textarea")
    inputs.forEach((element) => {
      element.disabled = !shouldShow && element.dataset.optional !== "true"
    })
  }
}
