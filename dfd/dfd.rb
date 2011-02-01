# the wiki is hosted on a server on which i can't install the mechanize gem, so the checking/parsing and importing are separate

require 'rubygems'
require 'Mechanize'
require 'uri'
require 'net/http'
require 'FileUtils'
require_relative 'person'

$OLD_FILE = 'people.dump'
$NEW_FILE = 'new_people.dump'

class Nokogiri::XML::NodeSet
  alias_method :orig_access, :[]
  def [](*args)
    if args[0].is_a? String
      find_all {|x| x.name == args[0]}.map &:text
    else
      orig_access *args
    end
  end
end

def self.check_new_profs
  agent = Mechanize.new

  root = 'http://dfd.dartmouth.edu/directory/show/'
  pages = []

  # 480 was highest as of jan 2011
  6.upto(480) do |n|
    begin
      pages[n] = agent.get root + n.to_s
    rescue Mechanize::ResponseCodeError
      next
    rescue StandardError => e
      puts n.to_s + ': ' + e.to_s
      next
    end
  end

  people = People.load $OLD_FILE
  new_people = People.new
  pages.each_index do |n|
    if pages[n] && !people.numbers[n]
      puts n
      p = Person.parse pages[n]
      puts p
      people.persons << p
      new_people.persons << p
      new_people.numbers[n] = true
      people.numbers[n] = true
      puts people.persons[n].inspect
      puts people.persons.size
      puts people.numbers[n].inspect
      puts people.numbers.size
      p.get_pic
    end
  end
  people.store $OLD_FILE
  new_people.store $NEW_FILE
end

check_new_profs
