require 'json'

class Movie < ApplicationRecord
  def self.all_ratings
    %w[G PG PG-13 R]
  end

  def self.with_ratings(ratings, sort_by)
    if ratings.nil?
      all.order sort_by
    else
      where(rating: ratings.map(&:upcase)).order sort_by
    end
  end
  
require 'json'

def self.find_in_tmdb(search_terms)
  api_key = ENV['TMDB_API_KEY'] || 'dummy_key'

  title = search_terms[:title]
  year = search_terms[:year]

  url = "https://api.themoviedb.org/3/search/movie?api_key=#{api_key}&query=#{title}"
  url += "&year=#{year}" unless year.blank?

  response = Faraday.get(url)

  data = JSON.parse(response.body)

  results = data["results"] || []

 
  movies = results.map do |movie|
    {
      title: movie["title"],
      release_date: movie["release_date"],
      rating: "R"   
    }
  end

  movies
end






end



