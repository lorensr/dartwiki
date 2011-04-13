require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative '../dfd/person'

require_relative 'types.rb'

$profs = People.load File.join(File.dirname(__FILE__), '..', 'dumps', 'people.dump')

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
        file = nil
        begin
          file = open(REMOTE_MEDIAN_ROOT + t.to_s + '.html')
        rescue
          begin
            file = open(REMOTE_MEDIAN_ROOT + t.to_s + '_median.html')
          rescue
            next
          end
        end

        page = Nokogiri::HTML file

        next if page.xpath('//title').inner_text == 'This Page Has Moved'
          
        copy file, local_file
        update_medians_term t, page
      end
    end
  end

  def copy src, dst
    File.open(dst, 'w') {|n| FileUtils.copy_stream(src, n)}
  end

  def get url
    local = File.join LOCAL_ROOT, url[url.rindex('/')+1..-1]
    unless File.exists? local
      p url
      f = open(url)
      copy f, local
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
    noko(REMOTE_ORC_ROOT + 'index.html') do |page|
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
    end
  end

  def parse_dept name, code
    noko(REMOTE_ORC_ROOT + code + '.html') do |page|
      next_p = page.xpath('//p[@class="coursetitle"]').first
      done = false
      course = nil
      offered = nil
      desc = nil
      while !done && next_p
        case next_p['class']
        when 'courseoffered', 'courseofferedbottom', 'pa14'
          course.offered = next_p.inner_text.strip
        when 'coursedescptnpar'
          desc = next_p.inner_text
          dist = desc =~ /Dist: /
          if dist
            p desc[dist..-1]
          end
          if course.description
            course.description << "\n\n" + next_p.inner_text
          else
            course.description = next_p.inner_text
          end
        when 'coursetitle'
          txt = next_p.inner_text
          space = txt.index ' '
          num = txt[0..space-1]
          title = txt[space+1..-1]
          num.chop! if num[-1] == '.'
          course = get_course code, num
          if course
            course.title = title.strip
          else
            course = Course.new code, num, nil, title.strip
            @courses << course
          end
        when 'subsectitle'
          ;
        else
          done = true
          puts next_p
        end
        next_p = next_p.next_element
      end
      puts 'done'
    end
  end

  def get_course dept, num
    cs = @courses.select {|c| c.subject == dept && c.number == num}
    sections = cs.map &:section
    cs[sections.index sections.min] unless sections.empty?
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
#    c.update_descriptions

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


