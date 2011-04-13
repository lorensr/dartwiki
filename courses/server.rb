require 'singleton'

class CourseSet
  attr_accessor :courses, :median_terms

  def initialize
    @median_terms = []
    @courses = []
  end
end

class Term
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
  attr_accessor(
                :instances, # hash: term => instance
                :subject,
                :number,
                :section,
                :description,
                :offered,
                :title
                )

  def initialize subject, number, section = nil, title = nil
    @instances = {}
    @subject = subject
    @number = number
    @section = section
    @title = title
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
    @subject == o.subject && @number == o.number && @section == o.section
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
    Course.new sub, num, sec
  end
end

class Instance
  attr_accessor :enrolled, :median

  def initialize enrolled, median
    @enrolled = enrolled
    @median = median
  end
end

