require 'nokogiri'
require 'open-uri'
require 'fileutils'

require_relative 'types.rb'

class Course
end

class CourseSet

  LOCAL_ROOT = File.join(File.dirname(__FILE__), 'pages')
  REMOTE_MEDIAN_ROOT = 'https://www.dartmouth.edu/~reg/courses/medians/'
  REMOTE_ORC_ROOT = 'https://www.dartmouth.edu/~reg/courses/desc/'

  def update_medians
    Term.parse('10s').upto(Term.now) do |t|
      local_file = File.join(LOCAL_ROOT, t.to_s)
      unless File.exists? local_file
        begin
          page = Nokogiri::HTML(open(REMOTE_MEDIAN_ROOT + t.to_s + '.html'))
        rescue
          begin
            page = Nokogiri::HTML(open(REMOTE_MEDIAN_ROOT + t.to_s + '_median.html'))
          rescue
            next
          end
        end

        next if page.title == 'This Page Has Moved'
          
        page.save local_file
        puts page.title
        update_medians_term t, page
      end
    end
  end

  def get url
    local = File.join LOCAL_ROOT, url[url.rindex('/')+1..-1]
    unless File.exists? local
      f = open(url)
      File.open(local, 'w') {|n| FileUtils.copy_stream(f, n)}
      f.close
    end
    File.open local
  end
      

  def update_medians_term term, page
    @median_terms << term
    
    rows = page.search 'tr'

    passed_header = false
    rows.each do |r|
      if r.inner_text =~ /med/i
        passed_header = true
        next
      end
      if passed_header
        cells = r.xpath('td').map &:inner_text
        foo, code, enrolled, median = cells.map &:strip
        
        course_idx = @courses.index code
        course = nil
        if course_idx
          course = @courses[course_idx]
        else
          course = Course.parse code
        end
        
        course.instances[term] = Instance.new enrolled, median
        
        @courses << course unless course_idx
      end
    end
  end


  def noko file_loc
    file = get file_loc
    yield Nokogiri::HTML file
    file.close
  end

  def update_descriptions
    file = get REMOTE_ORC_ROOT + 'index.html'
    page = Nokogiri::HTML file
    
    rows = page.search('tr').to_a
    rows.shift

    rows.each do |r|
      cells = r.xpath('td')
      name = cells.shift.inner_text
      courses = cells.shift.xpath 'a'
      
      unless courses.empty?
        url = courses[0]['href']
        code = url[url.rindex('/')+1..url.rindex('.')-1]
        parse_dept name, code
      end
    end

    file.close
  end

  def parse_dept name, code
    file = get REMOTE_ORC_ROOT + code
    page = Nokogiri::HTML file

    

    file.close
  end

  def self.update dump
    c = nil
    if File.exists? dump
      File.open dump do |f|
        c = Marshal.load f
      end
    else
      c = CourseSet.new
    end

    c.update_medians
    c.update_descriptions

    File.open dump, 'w' do |f|
      Marshal.dump c, f
    end
    
    puts c.median_terms
  end
end

=begin
    c = Course.new
    c.medians['09X'] = Median.new 20, 'A-'

    File.open 't.dump', 'w' do |f|
      Marshal.dump c, f
    end
    File.open 't.dump' do |f|
      c2 = Marshal.load f
      pp c2
    end
=end


