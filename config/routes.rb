Rails.application.routes.draw do

  get 'help/getting_started'
  get 'help/webapp_setup'

  authenticated :user do
    root :to => "nodes#index", as: :authenticated_root
  end
  root to: 'visitors#index'
  devise_for :users
  resources :users
  resources :nodes do
  	member do
  		post 'import'
      post 'export'
  	end
  end

  post 'input/read'

  get 'stats/:node_id/dashboard' => 'stats#dashboard', as: :dashboard_stats
  get 'stats/:node_id/time_series_data' => 'stats#time_series_data', as: :time_series_data_stats
  get 'stats/:node_id/yearly_data' => 'stats#yearly_data', as: :yearly_data_stats
  # get 'stats/:node_id/monthly' => 'stats#chart', as: :monthly_stats
  get 'stats/:node_id/monthly_data' => 'stats#monthly_data', as: :monthly_data_stats
  # get 'stats/:node_id/weekly' => 'stats#chart', as: :weekly_stats
  get 'stats/:node_id/weekly_data' => 'stats#weekly_data', as: :weekly_data_stats
  # get 'stats/:node_id/daily' => 'stats#chart', as: :daily_stats
  get 'stats/:node_id/daily_data' => 'stats#daily_data', as: :daily_data_stats
  get 'stats/:node_id/daily_per_month_data' => 'stats#daily_per_month_data', as: :daily_per_month_data_stats
  get 'stats/:node_id/slot_percentage_data' => 'stats#slot_percentage_data', as: :slot_percentage_data_stats
  # get 'stats/:node_id/real_time' => 'stats#chart', as: :real_time_stats
  get 'stats/:node_id/real_time_data' => 'stats#real_time_data', as: :real_time_data_stats
  get 'stats/:node_id/:chart' => 'stats#chart', as: :chart_stats, constraints: { chart: /yearly|monthly|weekly|daily|real_time|time_series|daily_per_month/ }
  get 'stats/:node_id/time_interval' => 'stats#time_interval', as: :time_interval_stats

end
