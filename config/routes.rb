require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  # MFA routes
  resource :mfa, controller: "mfa", only: [ :new, :create ] do
    get :verify
    post :verify, to: "mfa#verify_code"
    delete :disable
  end

  mount Lookbook::Engine, at: "/design-system"

  # Uses basic auth - see config/initializers/sidekiq.rb
  mount Sidekiq::Web => "/sidekiq"

  resources :family_exports, only: %i[new create index] do
    member do
      get :download
    end
  end

  resource :current_session, only: %i[update]

  resource :registration, only: %i[new create]
  resources :sessions, only: %i[new create destroy]
  resource :password_reset, only: %i[new create edit update]
  resource :password, only: %i[edit update]
  resource :email_confirmation, only: :new

  resources :users, only: %i[update destroy] do
    delete :reset, on: :member
    patch :rule_prompt_settings, on: :member
  end

  resource :onboarding, only: :show do
    collection do
      get :preferences
      get :goals
    end
  end

  namespace :settings do
    resource :profile, only: [ :show, :destroy ]
    resource :preferences, only: :show
    resource :hosting, only: %i[show update] do
      delete :clear_cache, on: :collection
    end
    resource :security, only: :show
  end

  resources :tags, except: :show do
    resources :deletions, only: %i[new create], module: :tag
    delete :destroy_all, on: :collection
  end

  namespace :category do
    resource :dropdown, only: :show
  end

  resources :categories, except: :show do
    resources :deletions, only: %i[new create], module: :category

    post :bootstrap, on: :collection
    delete :destroy_all, on: :collection
  end

  resources :budgets, only: %i[index show edit update], param: :month_year do
    get :picker, on: :collection

    resources :budget_categories, only: %i[index show update]
  end

  resources :charts, only: :index

  resources :liabilities, only: %i[new create edit update]

  resource :demo_transactions, only: :create

  resources :family_merchants, only: %i[index new create edit update destroy]

  resources :transfers, only: %i[new create destroy show update]

  resources :imports, only: %i[index new show create destroy] do
    member do
      post :publish
      put :revert
      put :apply_template
    end

    resource :upload, only: %i[show update], module: :import
    resource :configuration, only: %i[show update], module: :import
    resource :clean, only: :show, module: :import
    resource :confirm, only: :show, module: :import

    resources :rows, only: %i[show update], module: :import
    resources :mappings, only: :update, module: :import
  end

  resources :holdings, only: %i[index new show destroy]
  resources :trades, only: %i[show new create update destroy]
  resources :valuations, only: %i[show new create update destroy] do
    post :confirm_create, on: :collection
    post :confirm_update, on: :member
  end

  namespace :transactions do
    resource :bulk_deletion, only: :create
    resource :bulk_update, only: %i[new create]
  end

  resources :transactions, only: %i[index new create show update destroy] do
    resource :transfer_match, only: %i[new create]
    resource :category, only: :update, controller: :transaction_categories

    collection do
      delete :clear_filter
    end
  end

  resources :accountable_sparklines, only: :show, param: :accountable_type

  direct :entry do |entry, options|
    if entry.new_record?
      route_for entry.entryable_name.pluralize, options
    else
      route_for entry.entryable_name, entry, options
    end
  end

  resources :rules, except: :show do
    member do
      get :confirm
      post :apply
    end

    collection do
      delete :destroy_all
    end
  end

  resources :accounts, only: %i[index new show destroy], shallow: true do
    member do
      post :sync
      get :sparkline
      patch :toggle_active
    end

    collection do
      post :sync_all
    end
  end

  direct :edit_account do |model, options|
    route_for "edit_#{model.accountable_name}", model, options
  end

  resources :depositories, only: %i[new create edit update]
  resources :investments, only: %i[index new create edit update]
  resources :properties, only: %i[new create edit update] do
    member do
      get :balances
      patch :update_balances

      get :address
      patch :update_address
    end
  end
  resources :vehicles, only: %i[new create edit update]
  resources :credit_cards, only: %i[new create edit update]
  resources :loans, only: %i[new create edit update]
  resources :cryptos, only: %i[new create edit update]
  resources :other_assets, only: %i[new create edit update]
  resources :other_liabilities, only: %i[new create edit update]

  resources :securities, only: :index

  resources :invite_codes, only: %i[index create]

  resources :invitations, only: [ :new, :create, :destroy ] do
    get :accept, on: :member
  end

  resources :currencies, only: %i[show]

  resources :impersonation_sessions, only: [ :create ] do
    post :join, on: :collection
    delete :leave, on: :collection

    member do
      put :approve
      put :reject
      put :complete
    end
  end

  get "redis-configuration-error", to: "pages#redis_configuration_error"

  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "imports/:import_id/upload/sample_csv", to: "import/uploads#sample_csv", as: :import_upload_sample_csv

  root "pages#dashboard"
end
