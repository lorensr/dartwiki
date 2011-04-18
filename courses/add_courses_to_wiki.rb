require 'courses'

File.open 'dump' do |f|
  cs = Marshal.load f
  courses = cs.courses[22]
  [courses].each do |course|
    page = course.subject + '_' + course.number
    File.open 'tmp', 'w+' do |tmp|
      tmp.write course.to_wiki
    end
    
    `cat tmp | php /var/dartwiki-www/wiki/maintenance/edit.php -s "automatically generated" #{page}`
  end
end

