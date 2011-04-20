require_relative '../courses'
require_relative '../../../net-dnd/lib/net/dnd'

$dnd = Net::DND.start('dnd.dartmouth.edu', ['email'])

class Object
  def write text, page
    tmp do |f|
      f.write text
    end

    `cat tmp | php /var/dartwiki-www/wiki/maintenance/edit.php -s "automatically generated" #{page.gsub(' ','_')}`
  end

  def tmp
    File.open 'tmp', 'w+' do |f|
      yield f
    end
  end  

  def get_email name
    if (email = $dnd.find name).size == 1
      email[0].email
    elsif (email = $dnd.find name.split[0..1].join(' ')).size == 1
      email[0].email
    elsif (email = $dnd.find name.split[0]).size == 1
      email[0].email
    else
      nil
    end
  end
end

File.open 'dump' do |f|
  cs = Marshal.load f
  cs.departments.each do |name, code|

    email = get_email name

    tmp do |f|
      f.write name + ' (' + code + ')'
      if email
        f.write "\n[mailto:#{email} #{email}]"
      end
    end

    `cat tmp | php /var/dartwiki-www/wiki/maintenance/edit.php -s "automatically generated" Category:#{name.gsub(' ', '_')}`


    write "#REDIRECT [[Category:#{name}]]", code
    write "#REDIRECT [[Category:#{name}]]", name
  end

  $dnd.close
end

