require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'sass'
require 'slim'
require 'pony'
require 'data_mapper'
require 'will_paginate'
require 'will_paginate/data_mapper'
require 'dotenv'
require 'pry'

Dotenv.load

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/app')
require 'models'
require 'routers'
require 'helpers'

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/config')
require 'settings'

enable :sessions
