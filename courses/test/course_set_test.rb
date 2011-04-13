require 'test/unit'
require_relative '../courses'

class TestCourseSet < Test::Unit::TestCase
  def test_update_median_term
    cs = CourseSet.new
    page = Nokogiri::HTML open(File.dirname(__FILE__) + './pages/10X')
    cs.update_medians_term Term.parse('10x'), page
    page = Nokogiri::HTML open(File.dirname(__FILE__) + './pages/10S')
    cs.update_medians_term Term.parse('09x'), page
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
end

