Rails.application.routes.draw do
  root 'trades#index'
  resources :trades
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'market' => 'trades#markets'
end
