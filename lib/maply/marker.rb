require 'ostruct'
require "#{File.dirname(__FILE__)}/random_name"
module Maply
  class Marker < OpenStruct
    include Maply::RandomName
    
    def initialize(args = {})
      args.merge!(:name => short_code(true)) unless args[:name]
      super
    end
    
  end
end
