Rails.application.routes.draw do
  get  '/my/avatar', to: 'avatar_upload#new', as: :my_avatar
  post '/my/avatar', to: 'avatar_upload#create'
end