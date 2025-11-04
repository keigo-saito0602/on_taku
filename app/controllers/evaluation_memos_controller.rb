class EvaluationMemosController < ApplicationController
  before_action :set_event
  before_action :ensure_event_owner

  def index
    @evaluation_memos = @event.evaluation_memos.order(:category, :source_row)
  end

  def new
    @evaluation_memo = EvaluationMemo.new
  end

  def create
    file = memo_params[:file]
    raise ActionController::ParameterMissing, :file if file.blank?

    created = EvaluationMemo.import_from_csv(file, event: @event)
    redirect_to event_evaluation_memos_path(@event), success: "#{created.size}件のメモをインポートしました"
  rescue CSV::MalformedCSVError => e
    @evaluation_memo = EvaluationMemo.new
    flash.now[:alert] = "CSVの読み込みに失敗しました: #{e.message}"
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    @evaluation_memo = e.record
    flash.now[:alert] = "メモの登録に失敗しました: #{e.record.errors.full_messages.join(', ')}"
    render :new, status: :unprocessable_entity
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

  def memo_params
    params.require(:evaluation_memo).permit(:file)
  end
end
