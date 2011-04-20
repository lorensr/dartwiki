require 'test/unit'
require_relative '../courses'
require 'json'

class TestCourseSet < Test::Unit::TestCase
  def test_update_median_term
    cs = CourseSet.new
    page = Nokogiri::HTML open(File.join(File.dirname(__FILE__), *%w[.. pages 10X]))
    cs.update_medians_term Term.parse('10x'), page
    page = Nokogiri::HTML open(File.join(File.dirname(__FILE__), *%w[.. pages 10S]))
    cs.update_medians_term Term.parse('10s'), page
  end

  def test_update
    CourseSet.update 'dump'
  end

  def test_parse_dept
    cs = CourseSet.new
    cs.parse_dept 'test name', 'aaas'
  end

  def test_print
    File.open 'dump' do |f|
      pp Marshal.load f
    end
  end

  def test_json
    File.open 'dump' do |f|
      cs = Marshal.load(f)
      File.open('course_set.json', 'w') {|f| f.write(JSON.generate(cs)) }
    end
  end

  def test_print_notes
    x = []
    File.open 'dump' do |f|
      cs = Marshal.load(f)
      cs.courses.each do |c|
        # if c.note
        #   cs.link_note c.note
        # end

        #x << c.subject.to_s + ' ' + c.number.to_s

        x << c.title
      end
    end

    puts x.sort
  end

  def test_to_wiki
    dump_open do |cs|
      puts cs.courses[22].to_wiki cs.departments
    end
  end

  def dump_open
    File.open 'dump' do |f|
      cs = Marshal.load(f)
      yield cs
    end
  end    
end

