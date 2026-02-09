Rails.application.routes.draw do
  get  '/my/jpeg', to: 'avatar_upload#new', as: :my_jpeg
  post '/my/jpeg', to: 'avatar_upload#create'
end