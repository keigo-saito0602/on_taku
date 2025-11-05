module TimetableHelper
  def minutes_since_midnight(time)
    return 0 if time.blank?

    time.seconds_since_midnight.to_i / 60
  end

  def timeline_window(slots, padding: 30)
    return [ 17 * 60, 22 * 60 ] if slots.blank?

    start_minutes = slots.map { |slot| minutes_since_midnight(slot.start_time) }.compact.min || 0
    end_minutes = slots.map { |slot| minutes_since_midnight(slot.end_time) }.compact.max || 0
    [
      [ start_minutes - padding, 0 ].max,
      [ [ end_minutes + padding, start_minutes + 60 ].max, 24 * 60 ].min
    ]
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
end
