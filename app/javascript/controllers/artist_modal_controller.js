import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "title", "body"]

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

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = payload.name || "アーティスト"
    }

    if (this.hasBodyTarget) {
      this.bodyTarget.innerHTML = this.composeBody(payload)
    }

    if (this.hasDialogTarget) {
      this.dialogTarget.showModal()
    }
  }

  composeBody(payload) {
    const rows = []
    if (payload.kind) {
      rows.push(this.lineItem("区分", payload.kind))
    }
    if (payload.genre) {
      rows.push(this.lineItem("ジャンル", payload.genre))
    }
    if (payload.description) {
      rows.push(this.lineItem("紹介", payload.description))
    }
    if (payload.official_link) {
      const link = `<a href="${payload.official_link}" target="_blank" rel="noopener" class="text-sky-600 hover:text-sky-500">${payload.official_link}</a>`
      rows.push(this.lineItem("公式リンク", link))
    }
    if (Array.isArray(payload.social_links) && payload.social_links.length > 0) {
      const list = payload.social_links
        .map((link) => {
          const label = link.label ? `${link.label}: ` : ""
          return `<li><a href="${link.url}" target="_blank" rel="noopener" class="text-sky-600 hover:text-sky-500">${label}${link.url}</a></li>`
        })
        .join("")
      rows.push(`<div><div class="text-xs font-semibold text-slate-500 uppercase tracking-wide">SNS</div><ul class="mt-1 space-y-1 text-sm">${list}</ul></div>`)
    }
    if (Array.isArray(payload.members) && payload.members.length > 0) {
      const list = payload.members
        .map((member) => {
          const parts = [member.name, member.instrument, member.role].filter((part) => part && part.length > 0)
          return `<li>${parts.join(" / ")}</li>`
        })
        .join("")
      rows.push(`<div><div class="text-xs font-semibold text-slate-500 uppercase tracking-wide">メンバー</div><ul class="mt-1 space-y-1 text-sm">${list}</ul></div>`)
    }
    if (rows.length === 0) {
      rows.push('<p class="text-sm text-slate-500">詳細情報は登録されていません。</p>')
    }
    return rows.join("")
  }

  lineItem(label, value) {
    return `<div><div class="text-xs font-semibold text-slate-500 uppercase tracking-wide">${label}</div><div class="mt-1 text-sm text-slate-700">${value}</div></div>`
  }
}
