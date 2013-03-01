#!/usr/bin/env ruby
require 'open-uri'
require 'twitter'
require 'json'
require 'mongo'

include Mongo

data = JSON.parse(open("https://www.kansalaisaloite.fi/api/v1/initiatives?&limit=50&minSupportCount=0").read)
db = MongoClient.new("localhost", 27017).db("kansalaisaloite")
coll = db["aloitteet"]

Twitter.configure do |config|
    config.consumer_key       = ""
    config.consumer_secret    = ""
    config.oauth_token        = ""
    config.oauth_token_secret = ""
end

data.each do |obj|
    if obj['primaryLanguage'] == "fi"
        aloite = coll.find({"id" => obj['id']}).first
        url = obj['id'].gsub("/api/v1/initiatives/", "/fi/aloite/")

        if aloite.nil?
            if obj['name']['fi'].length > 100
                title = obj['name']['fi'][0...100] + "..."
            else
                title = obj['name']['fi']
            end
            
            message = "#{title} - #{url}"
            # puts message
            Twitter.update(message)

            coll.insert(obj)
        else
            uusiarvo = obj['totalSupportCount'].to_i / 5000
            vanhaarvo = aloite['totalSupportCount'].to_i / 5000

            if uusiarvo != vanhaarvo
                message = "Aloite #{url} - saavutti #{uusiarvo*5}k kannatuksen rajan! #kansalaisaloite"
                # puts message

                Twitter.update(message)

                coll.update({"id" => obj['id']}, {"$set" => {"totalSupportCount" => obj['totalSupportCount']}})
            end
        end
    end
end
