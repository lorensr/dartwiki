require_relative '../courses'

File.open 'dump' do |f|
  cs = Marshal.load f
  cs.courses.each do |course|
    page = course.subject + '_' + course.number
    File.open 'tmp', 'w+' do |tmp|
      tmp.write course.to_wiki cs.departments
    end
    
    `cat tmp | php /var/dartwiki-www/wiki/maintenance/edit.php -s "automatically generated" #{page}`
  end
end


