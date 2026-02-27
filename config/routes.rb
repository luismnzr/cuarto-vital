require "sidekiq/web"

Rails.application.routes.draw do
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Devise
  devise_for :users, path: "", path_names: {
    sign_in: "login",
    sign_out: "logout",
    sign_up: "signup",
    password: "password"
  }

  # Static pages
  root "pages#home"
  get "about", to: "pages#about"
  get "terms", to: "pages#terms"

  # Student-facing
  resources :classes, only: [:index, :show] do
    resources :reservations, only: [:create], shallow: true
    resources :waitlist_entries, only: [:create], shallow: true
  end
  resources :reservations, only: [:destroy]
  resources :waitlist_entries, only: [:destroy]
  resources :packages, only: [:index]

  # Checkout & Payments
  post "checkout/package/:package_id", to: "checkouts#create_package", as: :checkout_package
  post "checkout/subscription/:plan_id", to: "checkouts#create_subscription", as: :checkout_subscription
  get "checkout/success", to: "checkouts#success", as: :checkout_success
  post "billing/portal", to: "checkouts#customer_portal", as: :customer_portal

  # Webhooks
  post "webhooks/stripe", to: "webhooks/stripe#create"
  post "webhooks/wellhub", to: "webhooks/wellhub#create"

  # Profile
  get "profile", to: "profiles#show"
  get "profile/classes", to: "profiles#classes", as: :profile_classes
  get "profile/package", to: "profiles#package", as: :profile_package
  get "profile/subscription", to: "profiles#subscription", as: :profile_subscription
  get "profile/waitlists", to: "profiles#waitlists", as: :profile_waitlists
  get "profile/billing", to: "profiles#billing", as: :profile_billing

  # Admin namespace
  namespace :admin do
    get "/", to: "dashboard#show", as: :dashboard
    resources :users, only: [:index, :show, :new, :create, :edit, :update] do
      post :sell_package, on: :member
    end
    resources :classes, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      resources :checkins, only: [:create], controller: "class_checkins"
      delete "reservations/:reservation_id", to: "classes#remove_student", as: :remove_student
    end
    resources :class_templates, except: [:show]
    resources :categories, except: [:show]
    resources :packages
    resources :subscription_plans
    resources :reservations, only: [:index]
    resources :products, except: [:show]
    resources :orders, only: [:index, :show, :new, :create]
    resources :external_checkins, only: [:index, :new, :create] do
      patch :validate, on: :member
    end
    resources :wellhub_bookings, only: [:index, :show]
    get "settings", to: "settings#show"
    patch "settings", to: "settings#update"
    post "settings/sync_wellhub", to: "settings#sync_wellhub", as: :sync_wellhub
    get "reports", to: "reports#index"
  end

  # Teacher namespace
  namespace :teacher do
    get "/", to: "dashboard#show", as: :dashboard
    resources :classes, only: [:index, :show]
    resource :profile, only: [:show, :edit, :update], controller: "profile"
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
