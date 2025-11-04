class ArtistsController < ApplicationController
  before_action :set_artist, only: %i[show edit update destroy]
  before_action :require_organizer!, except: %i[index show]

  def index
    @artists =
      if current_user&.organizer?
        Artist.order(:name)
      else
        Artist.published.order(:name)
      end
  end

  def show; end

  def new
    @artist = Artist.new
    prepare_nested_forms
  end

  def create
    @artist = Artist.new(artist_params)

    if @artist.save
      redirect_to @artist, success: "アーティストを登録しました"
    else
      prepare_nested_forms
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_nested_forms
  end

  def update
    if @artist.update(artist_params)
      redirect_to @artist, success: "アーティスト情報を更新しました"
    else
      prepare_nested_forms
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @artist.destroy!
    redirect_to artists_path, notice: "アーティストを削除しました"
  end

  private

  def set_artist
    @artist = Artist.find(params[:id])
  end

  def artist_params
    params.require(:artist).permit(
      :name,
      :genre,
      :official_link,
      :kind,
      :published,
      social_links_attributes: %i[id label url position _destroy],
      members_attributes: %i[id name instrument role position _destroy]
    )
  end

  def prepare_nested_forms
    @artist.social_links.build(label: "", url: "") if @artist.social_links.empty?
    @artist.members.build(name: "", instrument: "", role: "") if @artist.members.empty?
  end
end
