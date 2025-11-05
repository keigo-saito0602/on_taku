import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

const TYPE_CLASSES = {
  performance: ["bg-emerald-50", "border-emerald-200"],
  changeover: ["bg-amber-50", "border-amber-200"],
  other: ["bg-slate-100", "border-slate-200"]
}

const ALL_TYPE_CLASSES = Object.values(TYPE_CLASSES).flat()
const SLOT_INCREMENT_MINUTES = 5

export default class extends Controller {
  static targets = [
    "list",
    "slot",
    "template",
    "performanceInput",
    "changeoverInput",
    "stageStart",
    "stageEnd",
    "stageDestroy",
    "kind"
  ]

  static values = {
    templates: Array,
    changeoverTemplates: Array
  }

  connect() {
    this.sortable = Sortable.create(this.listTarget, {
      handle: ".drag-handle",
      animation: 180,
      onEnd: () => {
        this.updatePositions()
        this.updateDeleteButtons()
      }
    })
    this.updatePositions()
    this.refreshSlotStyles()
    this.updateDeleteButtons()
  }

  disconnect() {
    if (this.sortable) this.sortable.destroy()
  }

  addPerformance() {
    this.insertSlot({ type: "performance" })
  }

  addChangeover() {
    this.insertSlot({ type: "changeover" })
  }

  addOther() {
    this.insertSlot({ type: "other" })
  }

  insertSlot({ type }) {
    const card = this.buildSlot({ type })
    this.listTarget.appendChild(card)
    this.updatePositions()
    this.updateDeleteButtons()
    card.scrollIntoView({ behavior: "smooth", block: "center" })
  }

  removeSlot(event) {
    const card = event.target.closest("[data-timetable-editor-target='slot']")
    if (this.visibleSlotCount() <= 1) return
    const destroyInput = card.querySelector("input[data-timetable-editor-target='destroy']")
    if (destroyInput) {
      destroyInput.value = "1"
      card.classList.add("slot-hidden")
    } else {
      card.remove()
    }
    this.updatePositions()
    this.updateDeleteButtons()
  }

  removeStage(event) {
    event.preventDefault()
    const destroyInput = this.hasStageDestroyTarget ? this.stageDestroyTarget : null
    if (destroyInput) destroyInput.value = "1"
    this.slotTargets.forEach((slot) => {
      const destroy = slot.querySelector("input[data-timetable-editor-target='destroy']")
      if (destroy) destroy.value = "1"
      slot.classList.add("slot-hidden")
    })
    this.element.classList.add("stage-hidden")
    this.updatePositions()
    this.updateDeleteButtons()
  }

  setPerformance(event) {
    const card = event.target.closest("[data-timetable-editor-target='slot']")
    this.applySlotType(card, "performance")
  }

  setChangeover(event) {
    const card = event.target.closest("[data-timetable-editor-target='slot']")
    this.applySlotType(card, "changeover")
  }

  setOther(event) {
    const card = event.target.closest("[data-timetable-editor-target='slot']")
    this.applySlotType(card, "other")
  }

  artistUpdated(event) {
    const card = event.target.closest("[data-timetable-editor-target='slot']")
    if (!card) return
    if (event.target.value) {
      this.applySlotType(card, "performance", { keepArtist: true })
      return
    }
    if (card.classList.contains("slot-hidden")) return
    const kindInput = card.querySelector("input[data-timetable-editor-target='kind']")
    const fallback = kindInput?.value || card.dataset.originalType || "performance"
    this.applySlotType(card, fallback, { keepArtist: false })
  }

  applySlotType(card, type, { keepArtist = false } = {}) {
    if (!card) return
    const changeoverInput = card.querySelector("input[data-timetable-editor-target='changeover']")
    const artistSelect = card.querySelector("select[data-timetable-editor-target='artist']")
    const label = card.querySelector(".slot-label")
    const kindInput = card.querySelector("input[data-timetable-editor-target='kind']")

    const normalized = ["performance", "changeover", "other"].includes(type) ? type : "performance"

    if (kindInput) kindInput.value = normalized
    if (changeoverInput) changeoverInput.value = normalized === "changeover" ? "true" : "false"

    switch (normalized) {
      case "changeover":
        if (artistSelect) {
          artistSelect.value = ""
          artistSelect.disabled = true
        }
        label.textContent = "転換"
        card.dataset.slotType = "changeover"
        card.dataset.originalType = "changeover"
        break
      case "other":
        if (artistSelect) {
          artistSelect.disabled = false
          if (!keepArtist) artistSelect.value = ""
        }
        label.textContent = "その他"
        card.dataset.slotType = "other"
        card.dataset.originalType = "other"
        break
      default:
        if (artistSelect) {
          artistSelect.disabled = false
          if (!keepArtist && !artistSelect.value) artistSelect.value = ""
        }
        label.textContent = "出演"
        card.dataset.slotType = "performance"
        card.dataset.originalType = card.dataset.originalType || "performance"
        break
    }

    this.applySlotStyle(card)
  }

  applyTemplates() {
    const performance = this.parseMinutesInput(this.performanceInputTarget?.value)
      ?? this.templatesValue?.[0]
      ?? 30
    const changeover = this.parseMinutesInput(this.changeoverInputTarget?.value)
      ?? this.changeoverTemplatesValue?.[0]
      ?? 10
    const explicitStart = this.parseMinutes(this.stageStartTarget?.value)

    if (!performance && !changeover && explicitStart === null) return

    let current = explicitStart
    if (current === null) {
      const first = this.slots().find((slot) => !this.isHidden(slot))
      current = first ? this.parseMinutes(this.getInput(first, "start").value) : 18 * 60
    }

    this.slots().forEach((slot) => {
      if (this.isHidden(slot)) return
      const isChangeover = slot.querySelector("input[data-timetable-editor-target='changeover']").value === "true"
      const duration = isChangeover ? (changeover || 0) : (performance || 0)
      const startInput = this.getInput(slot, "start")
      const endInput = this.getInput(slot, "end")
      startInput.value = this.formatMinutes(current)
      current += duration
      endInput.value = this.formatMinutes(current)
    })
  }

  distributeEvenly() {
    const startMinutes = this.parseMinutes(this.stageStartTarget?.value)
    const endMinutes = this.parseMinutes(this.stageEndTarget?.value)
    if (startMinutes === null || endMinutes === null || endMinutes <= startMinutes) return

    const slots = this.slots().filter((slot) => !this.isHidden(slot))
    if (slots.length === 0) return

    const changeoverDuration = this.parseMinutesInput(this.changeoverInputTarget?.value) ?? 0
    const totalMinutes = endMinutes - startMinutes

    const changeoverSlots = slots.filter((slot) => this.resolveSlotType(slot) === "changeover")
    const performerSlots = slots.filter((slot) => this.resolveSlotType(slot) !== "changeover")

    const totalChangeoverMinutes = changeoverSlots.length * changeoverDuration
    let remainingForPerformers = Math.max(totalMinutes - totalChangeoverMinutes, 0)
    let remainingPerformerCount = performerSlots.length

    let current = startMinutes

    slots.forEach((slot, index) => {
      const startInput = this.getInput(slot, "start")
      const endInput = this.getInput(slot, "end")
      const isLast = index === slots.length - 1
      const type = this.resolveSlotType(slot)

      let duration
      if (type === "changeover" && changeoverDuration > 0) {
        duration = changeoverDuration
      } else if (type === "changeover") {
        duration = 0
      } else if (remainingPerformerCount > 0) {
        if (remainingPerformerCount === 1 || isLast) {
          duration = remainingForPerformers
        } else {
          const average = remainingForPerformers / remainingPerformerCount
          duration = this.roundToIncrement(average)
          const minRemaining = (remainingPerformerCount - 1) * 5
          if (duration < 5 && remainingPerformerCount > 1) duration = 5
          if (remainingForPerformers - duration < minRemaining) {
            duration = Math.max(5, remainingForPerformers - minRemaining)
          }
        }
        remainingForPerformers = Math.max(0, remainingForPerformers - duration)
        remainingPerformerCount -= 1
      } else {
        duration = 0
      }

      let endValue = current + duration
      if (isLast) endValue = endMinutes
      endValue = Math.min(endValue, endMinutes)
      if (endValue < current) endValue = current

      startInput.value = this.formatMinutes(current)
      endInput.value = this.formatMinutes(endValue)
      current = endValue
    })
  }

  updatePositions() {
    let index = 1
    this.slots().forEach((slot) => {
      if (this.isHidden(slot)) return
      const positionInput = slot.querySelector("input[data-timetable-editor-target='position']")
      if (positionInput) positionInput.value = index++
    })
  }

  buildSlot({ type }) {
    const templateHtml = (this.templateTarget.innerHTML || "").trim()
    if (!templateHtml) {
      throw new Error("Timetable slot template is empty")
    }
    const html = templateHtml.replace(/NEW_RECORD/g, Date.now().toString())
    const wrapper = document.createElement("div")
    wrapper.innerHTML = html
    const card = wrapper.querySelector("[data-timetable-editor-target='slot']")
    if (!card) {
      throw new Error("Timetable slot template is missing slot markup")
    }

    card.dataset.originalType = type
    card.dataset.slotType = type

    this.applySlotType(card, type)

    const changeoverInput = card.querySelector("input[data-timetable-editor-target='changeover']")
    const duration = this.deriveDuration(changeoverInput.value === "true")
    const startValue = this.findNextStart()
    const endValue = this.formatMinutes(this.parseMinutes(startValue) + duration)

    const startInput = this.getInput(card, "start")
    const endInput = this.getInput(card, "end")
    startInput.value = startValue
    endInput.value = endValue
    this.applySlotStyle(card)
    return card
  }

  refreshSlotStyles() {
    this.slots().forEach((slot) => {
      if (this.isHidden(slot)) return
      this.applySlotStyle(slot)
    })
  }

  applySlotStyle(card) {
    if (!card) return
    const type = this.resolveSlotType(card)
    card.dataset.slotType = type
    card.classList.remove(...ALL_TYPE_CLASSES)
    const classes = TYPE_CLASSES[type] || TYPE_CLASSES.performance
    card.classList.add(...classes)
  }

  resolveSlotType(card) {
    if (!card) return "performance"
    const changeoverInput = card.querySelector("input[data-timetable-editor-target='changeover']")
    if (changeoverInput && changeoverInput.value === "true") {
      return "changeover"
    }
    const kindInput = card.querySelector("input[data-timetable-editor-target='kind']")
    if (kindInput && kindInput.value) return kindInput.value
    return card.dataset.slotType || "performance"
  }

  visibleSlotCount() {
    return this.slots().filter((slot) => !this.isHidden(slot)).length
  }

  updateDeleteButtons() {
    const visibleCount = this.visibleSlotCount()
    this.slots().forEach((slot) => {
      const button = slot.querySelector("[data-timetable-editor-target='deleteButton']")
      if (!button) return
      const hide = visibleCount <= 1 && !this.isHidden(slot)
      button.classList.toggle("hidden", hide)
      button.disabled = hide
    })
  }

  getInput(slot, kind) {
    return slot.querySelector(`input[data-timetable-editor-target='${kind}Input']`)
  }

  findNextStart() {
    const visibleSlots = this.slots().filter((slot) => !this.isHidden(slot))
    if (visibleSlots.length === 0) return this.formatMinutes(18 * 60)
    const last = visibleSlots[visibleSlots.length - 1]
    const endInput = this.getInput(last, "end")
    const endMinutes = this.parseMinutes(endInput.value) ?? 18 * 60
    return this.formatMinutes(endMinutes)
  }

  deriveDuration(changeover) {
    if (changeover) {
      const minutes = this.parseMinutesInput(this.changeoverInputTarget?.value)
      return minutes ?? this.changeoverTemplatesValue?.[0] ?? 10
    }
    const minutes = this.parseMinutesInput(this.performanceInputTarget?.value)
    return minutes ?? this.templatesValue?.[0] ?? 30
  }

  parseMinutesInput(value) {
    if (value === undefined || value === null || value === "") return null
    const minutes = parseInt(value, 10)
    if (Number.isNaN(minutes) || minutes < 0) return null
    return minutes
  }

  roundToIncrement(value) {
    if (!Number.isFinite(value)) return 0
    return Math.round(value / SLOT_INCREMENT_MINUTES) * SLOT_INCREMENT_MINUTES
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

  isHidden(slot) {
    return slot.classList.contains("slot-hidden")
  }

  slots() {
    return Array.from(this.listTarget.querySelectorAll("[data-timetable-editor-target='slot']"))
  }
}
