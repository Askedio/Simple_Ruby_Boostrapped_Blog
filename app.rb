require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-migrations'
require 'sinatra/reloader'
require 'slugify'

DataMapper.setup( :default, "sqlite3://#{Dir.pwd}/my_app.db" )

require_relative  'helpers'
require_relative  'routes/blog'
require_relative  'routes/public'
require_relative  'models/post'

class SimpleRubyBlog < Sinatra::Base
  set :root, File.dirname(__FILE__)

  helpers Sinatra::SimpleRubyBlog::Helpers

  register Sinatra::SimpleRubyBlog::Routing::BlogAdmin
  register Sinatra::SimpleRubyBlog::Routing::Public

end