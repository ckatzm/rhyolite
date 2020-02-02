require 'sinatra'
require 'net/http'
require 'RedCloth'

module DropboxFileHelpers
	DROPBOX_API_URL = 'https://api.dropboxapi.com/2'
	DROPBOX_CONTENT_URL = 'https://content.dropboxapi.com/2'
	# TODO: Error code handling for http connections
	def index
		uri = URI(DROPBOX_API_URL + '/files/list_folder')
		Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
			req = Net::HTTP::Post.new uri
			req['Authorization'] = "Bearer #{ENV['DROPBOX_TOKEN']}"
			req['Content-Type'] = 'application/json'
			req.body = { path: '/articles' }.to_json
			res = http.request req
			res.body
		end
	end

	def article(id)
		uri = URI(DROPBOX_CONTENT_URL + '/files/download')
		Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
			req = Net::HTTP::Post.new uri
			req['Authorization'] = "Bearer #{ENV['DROPBOX_TOKEN']}"
			req['Content-Type'] = 'text/plain'
			req['Dropbox-Api-Arg'] =  { path: '/articles/' + id }.to_json
			res = http.request req
			res.body
		end
	end
end

if ENV.has_key? 'DROPBOX_TOKEN'
	helpers DropboxFileHelpers
end
	

get '/' do
	erb :home, locals: { articles: index }
end

get '/articles/:id' do
	puts article params['id']
	erb :article, locals: { body: RedCloth.new(article(params['id'])).to_html }
end