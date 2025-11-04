Rails.application.routes.draw do
  # Reveal health status on /up
  get "up" => "rails/health#show", as: :rails_health_check

  root "events#index"

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create], controller: "registrations"
  resource :account, only: :show, controller: "accounts"

  resources :artists
  resources :discounts

  resources :events do
    member do
      get :edit_timetable
      patch :update_timetable
      post :publish
      patch :apply_discounts
    end

    resources :timetable_slots, except: :index
    resources :evaluation_memos, only: %i[index new create]
  end
end
