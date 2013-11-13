require 'rubygems'
require 'bundler/setup'
require './app'

$stdout.sync = true
run Sinatra::Application
