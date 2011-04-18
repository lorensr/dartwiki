# -*- coding: utf-8 -*-

module AutoJ
  def auto_j
    h = {}
    instance_variables.each do |e|
      o = instance_variable_get e.to_sym
      h[e[1..-1]] = (o.respond_to? :auto_j) ? o.auto_j : o;
    end
    h
  end
  def to_json *a
    auto_j.to_json *a
  end
end

class CourseSet
  include AutoJ

  attr_accessor :courses, :median_terms, :departments

  def initialize
    @median_terms = []
    @courses = []
    @departments = {}
  end

  # def to_json(*a)
  #   {
  #     'json_class'   => self.class.name,
  #     'data'         =>
  #     {
  #       'courses' => @courses,
  #       'median_terms' => @median_terms,
  #       'departments' => @departments
  #     }
  #   }.to_json(*a)
  # end
end

class Term
  include AutoJ

  attr_accessor :year, :quarter
  QUARTERS = ['W', 'S', 'X', 'F']

  def initialize year, quarter
    @year = year
    @quarter = quarter
  end

  def self.parse term
    Term.new term[0..1], QUARTERS.index(term[2].upcase)
  end

  def upto z
    a = self.clone
    while a != z.succ
      yield a
      a = a.succ
    end
  end

  def == o
    case o
    when String
      vars_match Term.parse o
    when Term
      vars_match o
    else
      return false
    end
  end

  def vars_match o
    @year == o.year && @quarter == o.quarter
  end

  def succ
    new_qtr = @quarter + 1
    new_yr = @year
    if new_qtr == 4
      new_qtr = 0
      new_yr = @year.succ
    end
    Term.new new_yr, new_qtr
  end

  def to_s
    @year + QUARTERS[@quarter]
  end

  def self.now
    Term.new Time.now.year.to_s[2..3], (Time.now.month / 4)
  end
end

class Course
  include AutoJ
  
  attr_accessor(
                :instances, # hash: term => instance
                :subject,
                :number,
                :section,
                :description,
                :offered,
                :title,
                :note,
                :distribs,
                :wcults,
                :profs # array of [name,term] pairs
                )

  def initialize subject, number, section = nil, title = nil
    @instances = {}
    @subject = subject
    @number = number
    @section = section
    @title = title
    @offered = ''
    @distribs = []
    @wcults = []
    @profs = []
  end

  # examples:
  # "Dist: LIT; WCult: CI (pending faculty approval). Colbert."
  # "Dist: LIT; WCult: NW. Franconi, Pastor (11W), Buéno, Walker (12W)."
  # "Dist: INT or SOC; WCult: NW. Haynes."
  # "Dist: LIT. Favor."
  # 
  # states = [:dist,:cult,:prof]
  # 
  def parse_distrib_and_prof desc, distrib
    cur = ''
    state = :dist
    desc[distrib+6..-1].each_char do |c|
      case state
      when :dist
        case c
        when '.'
          @distribs << cur
          state = :prof
          cur = ''
        when ';'
          @distribs << cur
          state = :cult
          cur = ''
        when ' '
          if cur[-2..-1] == 'or'
            cur = ''
            next
          else
            @distribs << cur
          end
          cur = ''
        else
          cur << c
        end
      when :cult
        case c
        when '.'
          @wcults << cur.strip
          state = :prof
          cur = ''
        when ' '
          if cur == '' or cur[-1] == ':'
            cur = ''
            next
          end
        else
          cur << c
        end
      when :prof
        case c
        when '.', ','
          if cur[-1] == ')'
            pair = cur.split
            pair[-1] = pair[-1][1..3]
            name = pair[0..-2]
            @profs << name + [pair[-1]]
          else
            @profs << [cur]
          end
          cur = ''
        when ' '
          if cur == ''
            next
          else
            cur << c
          end
        else
          cur << c
        end
      end
    end

    @profs.each do |pair|
      pair[0] = CourseSet.get_full_name pair.first
    end

    @distribs.uniq!
  end  

  def == o
    case o
    when String
      codes_match Course.parse(o)
    when Course
      codes_match o
    else
      false
    end
  end
  
  def codes_match o
    @subject == o.subject && @number == o.number # && @section == o.section
  end
  
  def self.parse s
    sub = ''
    num = ''
    sec = ''
    if s =~ /-/
      sub, num, sec = s.split '-'
    else
      sub = s[0..3]
      num = s[4..6]
      sec = s[7..8]
    end
    if num
      num.gsub! /^0+/, ''
    else
      puts s
    end
    Course.new sub, num, sec
  end

  def to_wiki departments
    dept = departments.key @subject
    wiki = "
{{Infobox course
| name                      = #{@subject} #{@number}: #{@title}
| department           = #{dept}
| offered                   = #{@offered}
| note                        = #{@note}
| distributives          = #{@distribs.map {|x| '[['+x+']]'}.join ', '}
| world_culture        = #{@wcults.map {|x| '[[World Culture/'+x+'|'+x+']]'}.join ', '}
| professors             = "

    @profs.each do |pair|
      if pair.size > 1
        wiki << pair[1] + ': '
      end
      wiki << "[[#{pair[0]}]], "
    end

    2.times {wiki.chop!}
      

    wiki << "
}}

'''#{@title}'''

== ORC Description ==

#{@description}

"

    unless @instances.empty?
      wiki << "
== Medians ==
{| class='wikitable'
|-
! Median
! Term
! Enrolled
|-"
      @instances.each do |term,instance|
        wiki << "
| #{instance.median}
| #{term}
| #{instance.enrolled}
|-"
      end

      wiki << "
|}

"
    end

    wiki << "
[[Category:Courses]]
[[Category:#{dept}]]"
    @distribs.each do |d|
      wiki << "
[[Category:#{d}]]"
    end
    
    @wcults.each do |wc|
      wiki << "
[[Category:World Culture/#{wc}]]"
    end
    wiki
  end
end

class Instance
  include AutoJ

  attr_accessor :enrolled, :median

  def initialize enrolled, median
    @enrolled = enrolled
    @median = median
  end
end

