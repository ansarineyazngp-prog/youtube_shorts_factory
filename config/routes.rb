# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route points directly to the Admin Dashboard
  root to: "admin/dashboard#index"

  namespace :admin do
    root to: "dashboard#index", as: :dashboard
    get "dashboard" => "dashboard#index"
    post "dashboard/trigger_daily_job" => "dashboard#trigger_daily_job", as: :trigger_daily_job_dashboard

    resources :short_videos do
      member do
        post :approve
        post :trigger_pipeline
      end
      collection do
        post :fetch_trending
      end
    end

    resource :youtube_account, only: [:show, :edit, :update] do
      post :connect
      get :oauth_callback
      delete :disconnect
    end
  end
end
