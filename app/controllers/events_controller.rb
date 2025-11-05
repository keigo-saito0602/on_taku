class EventsController < ApplicationController
  skip_before_action :require_login, only: %i[index show]
  before_action :set_event, only: %i[show edit update destroy publish edit_timetable update_timetable apply_discounts]
  before_action :authorize_event!, only: %i[edit update destroy publish edit_timetable update_timetable apply_discounts]
  before_action :require_organizer!, only: %i[new create]

  def index
    @events =
      if current_user&.organizer?
        current_user.events.includes(:timetable_slots, :artists).order(event_date: :asc)
      else
        Event.published.includes(:organizer).order(event_date: :asc)
      end
  end

  def show
    load_show_context
  end

  def new
    @event = current_user.events.build(event_date: Date.current + 1, event_fee: 0, drink_fee: 0)
  end

  def create
    @event = current_user.events.build(event_params)

    if @event.save
      redirect_to @event, success: "イベントを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @event.update(event_params)
      redirect_to @event, success: "イベントを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy!
    redirect_to events_path, notice: "イベントを削除しました"
  end

  def publish
    if @event.update(state: :published)
      redirect_to @event, success: "イベントを公開しました"
    else
      load_show_context
      message_lines = ["公開に必要な情報が不足しています。", *@event.errors.full_messages]
      flash.now[:alert] = message_lines.join(" ")
      flash.now[:alert_dialog_title] = "公開できません"
      flash.now[:alert_dialog] = message_lines.join("\n")
      render :show, status: :unprocessable_entity
    end
  end

  def edit_timetable
    @artists = Artist.order(:name)
    ensure_timetables!
  end

  def update_timetable
    if @event.update(timetable_params)
      redirect_to @event, success: "タイムテーブルを更新しました"
    else
      @artists = Artist.order(:name)
      ensure_timetables!
      render :edit_timetable, status: :unprocessable_entity
    end
  end

  def apply_discounts
    discount_ids = extract_discount_ids
    if @event.update(discount_ids:)
      redirect_to @event, success: "割引を更新しました"
    else
      load_show_context
      flash.now[:alert] = "割引を更新できませんでした"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_event!
    return if current_user&.organizer? && @event.organizer_id == current_user.id

    redirect_to events_path, alert: "操作権限がありません"
  end

  def event_params
    params.require(:event).permit(
      :name,
      :event_date,
      :venue,
      :event_fee,
      :drink_fee,
      :door_time,
      :start_time,
      :description
    )
  end

  def timetable_params
    params.require(:event).permit(
      event_timetables_attributes: [
        :id,
        :stage_name,
        :name,
        :position,
        :_destroy,
        timetable_slots_attributes: [
          :id,
          :artist_id,
          :start_time,
          :end_time,
          :changeover,
          :slot_kind,
          :stage_name,
          :position,
          :_destroy
        ]
      ]
    )
  end

  def ensure_timetables!
    if @event.event_timetables.empty?
      @event.event_timetables.build(stage_name: "Main", name: "Main", position: 0)
    end

    @event.event_timetables.each_with_index do |timetable, index|
      timetable.position ||= index
      timetable.stage_name = "Stage #{index + 1}" if timetable.stage_name.blank?
      timetable.name = timetable.stage_name if timetable.name.blank?
      slots = timetable.timetable_slots.sort_by { |slot| slot.position || slot.start_time }
      timetable.timetable_slots = slots
      if timetable.timetable_slots.empty?
        timetable.timetable_slots.build(
          start_time: Time.zone.parse("18:00"),
          end_time: Time.zone.parse("18:30"),
          changeover: false
        )
      end
    end
  end

  def load_show_context
    @event_timetables = @event.event_timetables.includes(timetable_slots: :artist).ordered
    @timetable_slots = @event_timetables.flat_map(&:timetable_slots)
    @available_discounts = Discount.ordered
    @discounted_price = @event.discounted_price
  end

  def extract_discount_ids
    raw_ids =
      params.fetch(:discount_assignment, {}).fetch(:ids, [])
    Array.wrap(raw_ids).flatten.reject(&:blank?).map(&:to_i)
  end
end
