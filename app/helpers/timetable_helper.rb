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

    window_start = (start_minutes - padding).floor
    window_end = (end_minutes + padding).ceil

    window_start = (window_start / 15).floor * 15
    window_end = (window_end / 15.0).ceil * 15

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
      members: artist.members.map { |member| { name: member.name, instrument: member.instrument, role: member.role } },
      edit_path: edit_artist_path(artist)
    }.to_json
  end

  def timetable_note_payload(slot)
    {
      title: "#{slot.start_time.strftime('%H:%M')}枠の備考",
      note: slot.note
    }.to_json
  end

  def grid_layout_for_slots(slots, window_start:, window_end:, step_minutes: 5)
    total_rows = ((window_end - window_start).to_f / step_minutes).ceil + 1
    items = []
    return { items:, column_count: 1, row_count: total_rows, step_minutes: } if slots.blank?

    sorted = slots.sort_by(&:start_time)
    column_endings = []

    sorted.each do |slot|
      slot_start = minutes_since_midnight(slot.start_time)
      slot_end = minutes_since_midnight(slot.end_time)
      column_index = column_endings.index { |ending| ending <= slot.start_time }
      if column_index.nil?
        column_index = column_endings.length
        column_endings << slot.end_time
      else
        column_endings[column_index] = slot.end_time
      end
      row_start = grid_row_index(slot_start, window_start, step_minutes)
      row_end = [ grid_row_index(slot_end, window_start, step_minutes), row_start + 1 ].max
      row_end = [ row_end, total_rows ].min
      items << { slot:, column: column_index, row_start:, row_end: }
    end

    {
      items:,
      column_count: [ column_endings.length, 1 ].max,
      row_count: total_rows,
      step_minutes:
    }
  end

  def grid_row_index(minute_value, base_minute, step)
    offset = [ minute_value - base_minute, 0 ].max
    (offset / step).floor + 1
  end
end
