require 'net/http'

class CharactersController < ApplicationController
    
    # GET /character/?name=:name
    def show

        query = params[:name]

        if query.blank?
            render :json => {error:400, message: "No query string in request"}, status: 400
            return
        end

        cached_value = Rails.cache.fetch(query, expires_in: 1.week) do
            char_http = Net::HTTP.new(char_api_uri.host, char_api_uri.port)
            char_http.use_ssl = true

            request = Net::HTTP::Get.new(char_api_uri.path + "?name=#{query.to_s}")

            response = char_http.request(request)

            # A 404 response from the API just means there are no results. I don't think this calls for an error. Return empty.
            if response.is_a? Net::HTTPNotFound
                render :json => []
                return
            end

            if response == nil || response.body == nil || response.body["results"] == nil
                # If something else has gone wrong here, throw a 500.
                # (In production code, we would log this for analysis!)
                render :json => {error:500, message: "Something went wrong, but it's not your fault."}, status: 500
                return
            end

            results = JSON.parse(response.body)["results"]

            output = []

            results.each do |char_result|
                output.push({
                    id: char_result["id"],
                    name: char_result["name"],
                    status: char_result["status"],
                    species: char_result["species"],
                    gender: char_result["gender"],
                    image: char_result["image"],
                    appearances_by_season: get_season_hash(char_result),
                })
            end

            output
        end

        render :json => cached_value
    end

    private

    def char_api_uri
        URI("https://rickandmortyapi.com/api/character")
    end

    def episode_api_uri
        URI("https://rickandmortyapi.com/api/episode/")
    end

    # Given JSON data about an episode from the R&M API, extract its season number as an integer
    def get_season_number(episode)
        # Each episode result will have an episode number code containing the season number (eg "S01E11")
        # The season number will be located between the characters "S" and "E".
        return episode["episode"].scan(/S(\d+)E/).first.first.to_i # First `first` finds the first match for "S01E"; second goes into the parens
    end

    # Given a result from the Character API, return a hash mapping season numbers to the number of appearances that character has in that season
    def get_season_hash(character)
        ep_http = Net::HTTP.new(episode_api_uri.host, episode_api_uri.port)
        ep_http.use_ssl = true

        # Get a list of episodes this character appears in.
        # Each item in the "episode" attribute is a URL ending with an episode ID. Find it.
        episode_ids = character["episode"].map{ |url| url.scan(/\d+$/).first.to_i } # Regex finds numbers at end of string
        
        # Query the episode endpoint of the R&M API with a string representation of this array without spaces
        ep_request = Net::HTTP::Get.new(episode_api_uri.path + episode_ids.to_s.gsub(" ",""))

        ep_response = ep_http.request(ep_request)

        ep_results = JSON.parse(ep_response.body)

        season_hash = {1=>0, 2=>0, 3=>0, 4=>0, 5=>0}

        ep_results.each do |episode|
            # Find the season number for this episode, and increment the counter for that season
            season = get_season_number(episode)
            season_hash[season] = season_hash[season] + 1
        end

        season_hash
    end
end
