import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "container", "panel", "title", "body", "editButton"]
  static values = {
    bodyClass: { type: String, default: "" }
  }

  open(event) {
    event.preventDefault()
    const payloadRaw = event.currentTarget.dataset.artistModalPayloadValue
    if (!payloadRaw) return

    let payload
    try {
      payload = JSON.parse(payloadRaw)
    } catch {
      return
    }

    this.previousFocus = document.activeElement

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = payload.title || payload.name || "詳細"
    }

    if (this.hasBodyTarget) {
      this.bodyTarget.innerHTML = this.composeBody(payload)
    }

    if (this.hasEditButtonTarget) {
      if (payload.edit_path) {
        this.editButtonTarget.classList.remove("hidden")
        this.editButtonTarget.href = payload.edit_path
      } else {
        this.editButtonTarget.classList.add("hidden")
        this.editButtonTarget.removeAttribute("href")
      }
    }

    this.show()
  }

  composeBody(payload) {
    const rows = []
    if (payload.kind) {
      rows.push(this.lineItem("区分", this.escapeHTML(payload.kind)))
    }
    if (payload.genre) {
      rows.push(this.lineItem("ジャンル", this.escapeHTML(payload.genre)))
    }
    if (payload.description) {
      rows.push(this.lineItem("紹介", this.formatMultiline(payload.description)))
    }
    if (payload.official_link) {
      const link = `<a href="${payload.official_link}" target="_blank" rel="noopener" class="text-sky-600 hover:text-sky-500">${payload.official_link}</a>`
      rows.push(this.lineItem("公式リンク", link))
    }
    if (Array.isArray(payload.social_links) && payload.social_links.length > 0) {
      const list = payload.social_links
        .map((link) => {
          const label = link.label ? `${this.escapeHTML(link.label)}: ` : ""
          const url = this.escapeHTML(link.url)
          return `<li><a href="${url}" target="_blank" rel="noopener" class="text-sky-600 hover:text-sky-500">${label}${url}</a></li>`
        })
        .join("")
      rows.push(`<div><div class="text-xs font-semibold text-slate-500 uppercase tracking-wide">SNS</div><ul class="mt-1 space-y-1 text-sm">${list}</ul></div>`)
    }
    if (Array.isArray(payload.members) && payload.members.length > 0) {
      const list = payload.members
        .map((member) => {
          const parts = [member.name, member.instrument, member.role]
            .filter((part) => part && part.length > 0)
            .map((part) => this.escapeHTML(part))
          return `<li>${parts.join(" / ")}</li>`
        })
        .join("")
      rows.push(`<div><div class="text-xs font-semibold text-slate-500 uppercase tracking-wide">メンバー</div><ul class="mt-1 space-y-1 text-sm">${list}</ul></div>`)
    }
    if (payload.note) {
      rows.push(this.lineItem("備考", this.formatMultiline(payload.note)))
    }
    if (rows.length === 0) {
      rows.push('<p class="text-sm text-slate-500">詳細情報は登録されていません。</p>')
    }
    return rows.join("")
  }

  lineItem(label, value) {
    return `<div><div class="text-xs font-semibold text-slate-500 uppercase tracking-wide">${this.escapeHTML(label)}</div><div class="mt-1 text-sm text-slate-700">${value}</div></div>`
  }

  formatMultiline(text) {
    return this.escapeHTML(text).replace(/\n/g, "<br>")
  }

  escapeHTML(text) {
    if (text === undefined || text === null) return ""
    return String(text)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
  }

  show() {
    if (this.hasBackdropTarget) this.backdropTarget.classList.remove("hidden")
    if (this.hasContainerTarget) this.containerTarget.classList.remove("hidden")
    if (this.bodyClassValue) document.body.classList.add(this.bodyClassValue)
    document.addEventListener("keydown", this.handleKeydown)
    this.focusFirstElement()
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasBackdropTarget) this.backdropTarget.classList.add("hidden")
    if (this.hasContainerTarget) this.containerTarget.classList.add("hidden")
    if (this.bodyClassValue) document.body.classList.remove(this.bodyClassValue)
    document.removeEventListener("keydown", this.handleKeydown)
    if (this.previousFocus && typeof this.previousFocus.focus === "function") {
      this.previousFocus.focus()
    }
  }

  handleKeydown = (event) => {
    if (event.key === "Escape") {
      event.preventDefault()
      this.close()
    }
  }

  focusFirstElement() {
    if (!this.hasPanelTarget) return
    const focusable = this.panelTarget.querySelector(
      'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])'
    )
    if (focusable && typeof focusable.focus === "function") {
      focusable.focus()
    } else if (this.hasPanelTarget && typeof this.panelTarget.focus === "function") {
      this.panelTarget.focus()
    }
  }
}
