require 'net/http'

class CharactersController < ApplicationController
    
    # GET /character/?name=:name
    def show
        uri = URI(api_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        byebug

        request = Net::HTTP::Get.new(uri.path + "?name=#{params[:name]}")

        response = http.request(request)

        body = JSON.parse(response.body)

        output = body

        render :json => output
    end

    private

    def api_url
        "https://rickandmortyapi.com/api/character"
    end
end
