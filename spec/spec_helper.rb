require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/maply'

Dir[File.join(File.dirname(__FILE__)+'/lib/*.rb')].sort.each { |lib| require lib }

Maply::Map.class_eval do
  RAILS_ROOT = File.dirname(__FILE__)
end