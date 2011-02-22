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

  def test_update_medians
    CourseSet.update 'dump'
  end
end

