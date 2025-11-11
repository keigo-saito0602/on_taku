class DiscountsController < ApplicationController
  before_action :require_organizer!
  before_action :set_discount, only: %i[show edit update destroy]

  def index
    @discounts = Discount.ordered
  end

  def new
    @discount = Discount.new(kind: :percentage, priority: next_priority)
  end

  def create
    @discount = Discount.new(discount_params)

    if @discount.save
      redirect_to discounts_path, success: "割引を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def update
    if @discount.update(discount_params)
      redirect_to discount_path(@discount), success: "割引を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @discount.destroy!
    redirect_to discounts_path, notice: "割引を削除しました"
  end

  private

  def set_discount
    @discount = Discount.find(params[:id])
  end

  def discount_params
    params.require(:discount).permit(
      :name,
      :kind,
      :value,
      :description,
      :priority,
      :category,
      :scope,
      :stacking_rule,
      :published,
      :start_at,
      :end_at,
      :minimum_amount,
      :minimum_quantity,
      :usage_limit_per_user,
      :usage_limit_total
    )
  end

  def next_priority
    Discount.maximum(:priority).to_i + 1
  end
end
