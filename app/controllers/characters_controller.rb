require 'net/http'

class CharactersController < ApplicationController
    
    # GET /character/?name=:name
    def show
        char_uri = URI(char_api_url)
        ep_uri = URI(episode_api_url)

        char_http = Net::HTTP.new(char_uri.host, char_uri.port)
        char_http.use_ssl = true
        ep_http = Net::HTTP.new(ep_uri.host, ep_uri.port)
        ep_http.use_ssl = true

        request = Net::HTTP::Get.new(char_uri.path + "?name=#{params[:name]}")

        response = char_http.request(request)

        if response == nil || response.body == nil || response.body["results"] == nil
            # throw an error
        end

        results = JSON.parse(response.body)["results"]

        output = []

        results.each do |char_result|

            # Get a list of episode numbers this character appears in.
            # Each item in the "episode" attribute is a URL ending with an episode number. Find it.
            episode_ids = char_result["episode"].map{ |url| url.scan(/\d+$/).first.to_i }
            
            # Query the episode endpoint of the R&M API with a string representation of this array without spaces
            ep_request = Net::HTTP::Get.new(ep_uri.path + episode_ids.to_s.gsub(" ",""))

            ep_response = ep_http.request(ep_request)

            ep_results = JSON.parse(ep_response.body)

            season_hash = Hash.new

            ep_results.each do |episode|
                # Each episode result will have an episode number code containing the season number (eg "S01E11")
                season = episode["episode"].scan(/S(\d+)E/)[0][0].to_i
                
                # If the season hash already contains an entry for this season, increment it. Otherwise, set to 1.
                if(season_hash.key?(season))
                    season_hash[season] = season_hash[season] + 1
                else
                    season_hash[season] = 1
                end
            end

            output.push({
                id: char_result["id"],
                name: char_result["name"],
                status: char_result["status"],
                species: char_result["species"],
                gender: char_result["gender"],
                image: char_result["image"],
                appearances_by_season: season_hash,
            })
        end

        render :json => output
    end

    private

    def char_api_url
        "https://rickandmortyapi.com/api/character"
    end

    def episode_api_url
        "https://rickandmortyapi.com/api/episode/"
    end
end
