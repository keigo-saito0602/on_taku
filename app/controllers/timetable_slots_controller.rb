class TimetableSlotsController < ApplicationController
  before_action :set_event
  before_action :ensure_event_owner
  before_action :set_timetable_slot, only: %i[edit update destroy]
  before_action :set_event_timetable_for_form, only: %i[new create edit update]
  before_action :set_artists, only: %i[new create edit update]
  before_action :prepare_form_support, only: %i[new create edit update]

  def new
    @timetable_slot = @event_timetable.timetable_slots.build(changeover: false)
  end

  def create
    @timetable_slot = @event_timetable.timetable_slots.build(timetable_slot_params)

    if @timetable_slot.save
      redirect_to @event, success: "タイムテーブルを追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @timetable_slot.update(timetable_slot_params)
      redirect_to @event, success: "タイムテーブルを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @timetable_slot.destroy!
    redirect_to @event, notice: "タイムテーブルを削除しました"
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def ensure_event_owner
    require_organizer!
    return if @event.organizer_id == current_user.id

    redirect_to events_path, alert: "操作権限がありません"
  end

  def set_timetable_slot
    @timetable_slot = @event.timetable_slots.includes(:event_timetable).find(params[:id])
  end

  def timetable_slot_params
    params.require(:timetable_slot).permit(:artist_id, :start_time, :end_time, :changeover, :stage_name)
  end

  def set_artists
    @artists = Artist.order(:name)
  end

  def prepare_form_support
    @existing_slots = @event_timetable.timetable_slots.includes(:artist).order(:start_time)
    @time_options = build_time_options
    @duration_templates = [
      { label: "30分", minutes: 30 },
      { label: "60分", minutes: 60 }
    ]
  end

  def build_time_options
    Array.new(24 * 12) do |index|
      minutes = index * 5
      hour = minutes / 60
      minute = minutes % 60
      value = format("%02d:%02d", hour, minute)
      [ value, value ]
    end
  end

  def set_event_timetable_for_form
    @event_timetable =
      if defined?(@timetable_slot) && @timetable_slot.present?
        @timetable_slot.event_timetable
      elsif params[:event_timetable_id].present?
        @event.event_timetables.find_by(id: params[:event_timetable_id])
      end

    @event_timetable ||= begin
      if @event.event_timetables.exists?
        @event.event_timetables.order(:position, :id).first
      else
        @event.event_timetables.create!(
          stage_name: "Main Stage",
          name: "Main Stage",
          position: 0
        )
      end
    end
  end
end
