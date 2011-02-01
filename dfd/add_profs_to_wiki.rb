$LOAD_PATH.unshift File.dirname(__FILE__)
require 'person'

$NEW_FILE = 'new_people.dump'

ppl = People.load $NEW_FILE

ppl.persons[300..-1].each_with_index do |p, i|
  page = p.name.gsub(' ','_')
  puts i.to_s
  if `/usr/local/php5/bin/php html/wiki/maintenance/getText.php #{page}` == '' && page != 'Dartmouth_Faculty_Directory'
    puts page + ' ' + i.to_s + ' ' + ppl.numbers[i].to_s
    File.open 'tmp', 'w+' do |f|
      f.write p.wiki if p
    end
    
    `cat tmp | /usr/local/php5/bin/php html/wiki/maintenance/edit.php -s "import from DFD" #{page}`
  end
end


