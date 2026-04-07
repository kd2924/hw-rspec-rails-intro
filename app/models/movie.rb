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
  
def self.find_in_tmdb(search_terms)
  api_key = ENV['TMDB_API_KEY'] || 'dummy_key'

  title = CGI.escape(search_terms[:title].to_s)
  language = search_terms[:language]

  url = "https://api.themoviedb.org/3/search/movie?api_key=#{api_key}&query=#{title}&language=#{language}"

  Faraday.get(url)
end






end



