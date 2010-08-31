require "rubygems"
require "bundler"
Bundler.setup

require 'sinatra'

set :env, :development
set :port, 4567
disable :run, :reload

require 'blarghhhh.rb'

run Blarghhhh
