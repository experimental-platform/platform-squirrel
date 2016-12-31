STDOUT.sync = STDERR.sync = true
RACK_ENV = ENV.fetch('RACK_ENV', 'development')
require 'bundler'
Bundler.require :default, RACK_ENV
require 'pathname'
require 'logger'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../app')
require 'squirrel'