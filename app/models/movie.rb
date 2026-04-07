require 'json'
require 'faraday'

class Movie < ApplicationRecord
  class TMDBError < StandardError; end

  TMDB_ENDPOINT = 'https://api.themoviedb.org/3/search/movie'.freeze

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
    options = normalize_search_terms(search_terms)
    return [] if options[:title].blank?

    response = Faraday.get(TMDB_ENDPOINT, build_query_params(options))
    return [] if response.nil?
    payload = parse_tmdb_payload!(response)

    Array(payload['results']).map do |movie|
      {
        title: movie['title'],
        release_date: movie['release_date'],
        description: movie['overview'],
        tmdb_id: movie['id'],
        rating: 'R'
      }
    end
  rescue Faraday::Error => e
    raise TMDBError, "TMDb request failed: #{e.message}"
  end

  def self.normalize_search_terms(search_terms)
    hash =
      if defined?(ActionController::Parameters) && search_terms.is_a?(ActionController::Parameters)
        search_terms.to_unsafe_h
      elsif search_terms.is_a?(Hash)
        search_terms
      else
        { title: search_terms }
      end

    {
      title: hash[:title] || hash['title'],
      language: hash[:language] || hash['language'],
      year: hash[:year] || hash['year']
    }.compact
  end
  private_class_method :normalize_search_terms

  def self.build_query_params(options)
    params = {
      api_key: ENV['TMDB_API_KEY'] || 'dummy_key',
      query: options[:title]
    }

    language = options[:language].presence
    params[:language] = language unless language.blank? || language.casecmp('all').zero?
    params[:year] = options[:year] if options[:year].present?

    params
  end
  private_class_method :build_query_params

  def self.parse_tmdb_payload!(response)
    raise TMDBError, 'TMDb request failed with no response.' if response.nil?

    body = response.body.to_s
    payload = body.empty? ? {} : JSON.parse(body)

    if response.status.to_i >= 400 || payload['success'] == false
      message = payload['status_message'].presence || "TMDb request failed with status #{response.status}"
      raise TMDBError, message
    end

    payload
  rescue JSON::ParserError
    raise TMDBError, 'TMDb returned an invalid response. Please try again later.'
  end
  private_class_method :parse_tmdb_payload!
end
