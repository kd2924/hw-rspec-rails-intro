Rottenpotatoes::Application.routes.draw do
  get 'search_tmdb', to: 'movies#search_tmdb'
  resources :movies
  # map '/' to be a redirect to '/movies'
  root to: redirect('/movies')
end
