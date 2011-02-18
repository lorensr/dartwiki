require 'rubygems'
require 'Mechanize'
require 'uri'
require 'net/http'

class Course
  attr_accessor(
                :medians # hash: term => Median object
                )

  def initialize
    @medians = {}
  end
  
  def self.load file
    if File.exists? file
      Marshal.load File.open(file, 'r').read
    else
      FileUtils.touch file
      Course.new
    end
  end
  
  def store file
    File.open file, 'w' do |f|
      f.write Marshal.dump self
    end
  end

  def marshal_dump
    [@medians]
  end

  def marshal_load ary
     @medians = ary[0]
  end
end

class Median
  attr_accessor :enrolled, :median
end

def update_medians dump
  courses = Course.load dump
  pp courses
end

update_medians 'courses.dump'
