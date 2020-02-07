require 'sinatra'
require 'rack/cache'
require 'net/http'
require 'RedCloth'

module DropboxFileHelpers
	DROPBOX_API_URL = 'https://api.dropboxapi.com/2'
	DROPBOX_CONTENT_URL = 'https://content.dropboxapi.com/2'
	# TODO: http error code handling, add logging too, deduplicate this code
	def list_folder(folder)
	uri = URI(DROPBOX_API_URL + '/files/list_folder')
		Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
			req = Net::HTTP::Post.new uri
			req['Authorization'] = "Bearer #{ENV['DROPBOX_TOKEN']}"
			req['Content-Type'] = 'application/json'
			req.body = { path: '/' + folder }.to_json
			res = http.request req
			res.body
		end
	end

	def get_file(path)
		uri = URI(DROPBOX_CONTENT_URL + '/files/download')
		Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
			req = Net::HTTP::Post.new uri
			req['Authorization'] = "Bearer #{ENV['DROPBOX_TOKEN']}"
			req['Content-Type'] = 'text/plain'
			req['Dropbox-Api-Arg'] = { path: path }.to_json
			res = http.request req
			res.body
		end
	end
end

module RenderHelpers
	def to_html(content)
		if params['ext'] == '.txt'
			RedCloth.new(content).to_html
		elsif params['ext'] == '.md'
			'' # TODO
		elsif params['ext'] == '.html'
			content
		else
			halt(400)
		end
	end
end

if ENV.has_key? 'DROPBOX_TOKEN'
	helpers DropboxFileHelpers
end

helpers RenderHelpers
	
use Rack::Cache do
	set :verbose, true
	set :metastore, 'file:/var/cache/rack/meta'
	set :entitystore, 'file:/var/cache/rack/body'
	if ENV['RUBY_ENV'] == 'dev'
		set :allow_reload, true
	end
end

get '/' do
	erb :home, locals: { posts: JSON.parse(list_folder('posts'))['entries'],
											 images: JSON.parse(list_folder('images'))['entries'] }
end

get %r{/posts/.+|/site/.+} do
	erb :post, locals: { content: to_html(get_file request.path + params['ext']) }
end

get '/images/:file' do
	get_file request.path
end