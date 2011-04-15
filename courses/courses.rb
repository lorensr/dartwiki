# -*- coding: utf-8 -*-
require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative '../dfd/person'

require_relative 'types.rb'

$people = People.load File.join(File.dirname(__FILE__), '..', 'dumps', 'people.dump')

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
        when 'courseoffered', 'courseofferedbottom', 'pa14', 'crsoffered1', 'crsoffered2', 'crsofferedmid', 'courseoffered1', 'courseoffered-mid', 'courseoffered2'
          course.offered += ' ' unless course.offered == ''
          course.offered << next_p.inner_text.strip
        when 'coursedescptnpar'
          desc = next_p.inner_text
          if desc
            distrib = desc =~ /Dist: /
            if distrib
              course.parse_distrib_and_prof desc, distrib
              desc = desc[0..distrib-1]
            else
              words = desc.split
              if words.size == 1 or words[-2][-1] == '.'
                last_name = words[-1][0..-2]
                course.profs << [CourseSet.get_full_name(last_name)]
                desc = words[0..-2].join ' '
              end
            end
          end
         
          if course.description
            course.description << "\n\n" + desc.strip
          else
            course.description = desc.strip
          end
        when 'coursetitle', 'normal-web-'
          txt = next_p.inner_text
          space = txt.index ' '
          num = txt[0..space-1]
          title = txt[space+1..-1]
          
          paren = title.index '('
          note = nil
          if paren
            note = title[paren+1..title.index(')')-1]
            title = title[0..paren-2]
          end
          
          num.chop! if num[-1] == '.'

          # remove leading zeros
          num.gsub!(/^0+/,'')
          
          course = get_course code, num
          if course
            course.title = title.strip
          else
            course = Course.new code.upcase, num, nil, title.strip
            @courses << course
          end
          course.note = note
        when 'subsectitle', 'normal', 'bodypar', 'subsectitle2', 'firstpar'
          ;
        when 'bodyparsmall', 'footnote-link'
          done = true
        else
          done = true
          puts code
          puts next_p
        end
        next_p = next_p.next_element
      end
      puts 'done'
    end
  end

  def self.get_full_name last_name
    matches = $people.persons.select {|p| p.match? last_name}
    if matches.size == 1
      matches.first.name
    else
      last_name
    end
  end    
    


  def get_course dept, num
    cs = @courses.select { |c|
      c.subject == dept &&
      (c.number == num or c.number.delete '0' == num)
    }
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


