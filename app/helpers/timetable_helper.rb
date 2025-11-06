module TimetableHelper
  def minutes_since_midnight(time)
    return 0 if time.blank?

    time.seconds_since_midnight.to_i / 60
  end

  def timeline_window(slots, padding: 30)
    return [ 17 * 60, 22 * 60 ] if slots.blank?

    starts = slots.map { |slot| minutes_since_midnight(slot.start_time) }.compact
    ends = slots.map { |slot| minutes_since_midnight(slot.end_time) }.compact

    start_minutes = starts.min || 0
    end_minutes = [ ends.max || start_minutes, start_minutes + 30 ].max

    window_start = ((start_minutes - padding) / 60).floor * 60
    window_end = ((end_minutes + padding) / 60.0).ceil * 60

    window_start = [ window_start, 0 ].max
    window_end = [ [ window_end, window_start + 60 ].max, 24 * 60 ].min

    [ window_start, window_end ]
  end

  def slot_label_and_color(slot)
    case slot.slot_kind
    when "changeover"
      [ "転換", "bg-amber-100 text-amber-700 border-amber-200" ]
    when "other"
      [ "その他", "bg-slate-100 text-slate-600 border-slate-200" ]
    else
      [ "出演", "bg-emerald-100 text-emerald-700 border-emerald-200" ]
    end
  end

  def artist_modal_payload(artist)
    return "{}" if artist.blank?

    {
      name: artist.name,
      genre: artist.genre.presence,
      kind: artist.kind_i18n,
      description: artist.try(:description).presence,
      official_link: artist.official_link.presence,
      social_links: artist.social_links.map { |link| { label: link.label, url: link.url } },
      members: artist.members.map { |member| { name: member.name, instrument: member.instrument, role: member.role } }
    }.to_json
  end

  def timetable_note_payload(slot)
    {
      name: "#{slot.start_time.strftime('%H:%M')}枠の備考",
      note: slot.note
    }.to_json
  end
end
