class MoviesController < ApplicationController
  before_action :force_index_redirect, only: [:index]

  def show
    id = params[:id] # retrieve movie ID from URI route
    @movie = Movie.find(id) # look up movie by unique ID
    # will render app/views/movies/show.<extension> by default
  end

  def index
    @all_ratings = Movie.all_ratings
    @movies = Movie.with_ratings(ratings_list, sort_by)
    @ratings_to_show_hash = ratings_hash
    @sort_by = sort_by
    # remember the correct settings for next time
    session['ratings'] = ratings_list
    session['sort_by'] = @sort_by
  end

  def new
    # default: render 'new' template
  end

  def create
    @movie = Movie.create!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully created."
    redirect_to movies_path
  end

  def search_tmdb
    @movies = []
    search_terms = build_search_terms

    if search_terms.blank?
      flash.now[:warning] = 'Please enter a movie title'
      render :search_tmdb and return
    end

    @movies = Movie.find_in_tmdb(search_terms)
    flash.now[:warning] = 'No movies found' if @movies.blank?
  rescue Movie::TMDBError => e
    Rails.logger.warn("TMDb error: #{e.message}")
    flash.now[:warning] = e.message
    @movies = []
    render :search_tmdb
  end

  def add_movie
    movie = Movie.create!(movie_params)
    flash[:notice] = "#{movie.title} was successfully added to RottenPotatoes."
    redirect_to search_path
  rescue ActiveRecord::RecordInvalid => e
    flash[:warning] = e.message
    redirect_to search_path
  end

  def edit
    @movie = Movie.find params[:id]
  end

  def update
    @movie = Movie.find params[:id]
    @movie.update!(movie_params)
    flash[:notice] = "#{@movie.title} was successfully updated."
    redirect_to movie_path(@movie)
  end

  def destroy
    @movie = Movie.find(params[:id])
    @movie.destroy
    flash[:notice] = "Movie '#{@movie.title}' deleted."
    redirect_to movies_path
  end

  private

    def movie_params
      params.require(:movie).permit(:title, :rating, :description, :release_date)
    end

    def build_search_terms
      term_from_params = params[:search_terms].presence
      explicit_filters = params[:movie_year].present? || params[:language].present?

      return structured_search_terms if term_from_params.blank?
      return term_from_params unless explicit_filters

      structured_search_terms(term_from_params)
    end

    def structured_search_terms(title = nil)
      title ||= params[:movie_title].presence
      return if title.blank?

      terms = { title: title }
      terms[:year] = params[:movie_year].presence if params[:movie_year].present?
      terms[:language] = params[:language].presence if params[:language].present?
      terms
    end

  def force_index_redirect
    return unless !params.key?(:ratings) || !params.key?(:sort_by)

    flash.keep
    url = movies_path(sort_by: sort_by, ratings: ratings_hash)
    redirect_to url
  end

  def ratings_list
    params[:ratings]&.keys || session[:ratings] || Movie.all_ratings
  end

  def ratings_hash
    ratings_list.to_h { |item| [item, "1"] }
  end

  def sort_by
    params[:sort_by] || session[:sort_by] || 'id'
  end
end
