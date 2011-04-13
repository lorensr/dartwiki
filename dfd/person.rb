
class String
  def sentence
    self[0] = self[0].capitalize
    self
  end
end

class Person
  attr_accessor(
                :name,
                :titles,
                :pic,
                :departments,
                :links,
                :email,
                :phone,
                :office,
                :education,
                :areas_of_expertise,
                :selected_works,
                :current_projects
                )

  def match? last_name
    name[name.index(' ')..-1].include? last_name
  end

  def marshal_dump
    [@name, @titles, @pic, @departments, @links, @email, @phone, @office, @education, @areas_of_expertise, @selected_works, @current_projects]
  end

  def marshal_load ary
    @name, @titles, @pic, @departments, @links, @email, @phone, @office, @education, @areas_of_expertise, @selected_works, @current_projects = ary
  end

  def wiki
    template +
      "
=Research=
==Areas of Expertise==
#{make_list areas_of_expertise}
==Publications==
#{make_list selected_works}
==Current Projects==
#{make_list current_projects}


[[Category:Professors]]
"    + categories
  end

  def categories
    departments.map {|x| "[[Category:#{x} Professors]]"}.join "\n"
  end
  
  def make_list ary
    ary.map {|x| '* ' + x}.join "\n"
  end
  
  def template
    "
{{Infobox person
| honorific_prefix          = Professor
| name                      = #{name}
| image                     = #{name}.jpg
| email                     = #{email}
| phone                     = #{phone}
| office                     = #{office}
| title                     = #{titles.join '<br />'}
| education                 = #{education.join '<br />'}
| website                   = #{links[0]}
}}
"
  end  

  def get_pic
    if name
      dir = File.join(File.dirname(__FILE__), 'img')
      file = File.join(dir, name.gsub(' ', '_') + '.jpg')
      if File.exist? file
        return
      end
      
      begin
        url = URI.parse pic
        Net::HTTP.start url.host do |conn|
          resp = conn.get url.path
          open file, 'w' do |f|
            f.write resp.body
          end
        end
      rescue StandardError
        return
      end
    else
      pp self
    end
  end

  def self.parse page

    p = Person.new
    p.name = page.search('h1')[1].text
    titles_container = page.search("td[@id='titles']")[0]
    p.titles = titles_container.children.map(&:text).find_all {|x| x.strip != ''} if titles_container

    begin
      p.pic = page.image_urls.find {|x| x =~ /images\/upload/}
    rescue URI::InvalidURIError
    end
    
    pre_depts = find page, /Departments and Programs/
    depts_ul = pre_depts.parent.next.next if pre_depts
    p.departments = depts_ul.children['li'] if depts_ul

    pre_links = find page, /Related Links/
    links_ul = pre_links.parent.next.next if pre_links
    p.links = links_ul.children['li'] if links_ul

    pre_contacts = find page, /Contact Information/
    if pre_contacts
      contacts_p = pre_contacts.parent.next.next 
      var = nil
      contacts_p.children.each do |node|
        if var
          p.instance_variable_set var, node.text.strip
          var = nil
        elsif node.to_s =~ /<b>Email:/
          var = :@email
        elsif node.to_s =~ /<b>Phone:/
          var = :@phone
        elsif node.to_s =~ /<b>Office:/
          var = :@office
        end
      end
    end

    if pre_contacts
      education_tr = contacts_p.parent.parent.next
    else
      pre_education = find page, /Education/
      education_tr = pre_education.parent.parent.parent if pre_education
    end
    
    p.education = education_tr.xpath('./td/p').text.split(';').map &:strip if education_tr

    pre_areas = find page, /Areas of Expertise/
    p.areas_of_expertise = pre_areas.parent.next.next.text.split(';').map(&:strip).map &:sentence if pre_areas

    pre_works = find page, /Selected Works/
    p.selected_works = pre_works.parent.parent.xpath('./ul').children.map &:text if pre_works

    pre_projs = find page, /Current Projects/
    p.current_projects = pre_projs.parent.next.next.text.split(';').map &:strip if pre_projs

    p
  end

  def self.find page, regex
    page.search('//text()').find {|x| x.text =~ regex}
  end
end

class People

  attr_accessor :numbers, :persons

  def initialize
    @numbers = []
    @persons = []
  end
  
  def self.load file
    if File.exists? file
      Marshal.load File.open(file, 'r').read
    else
      FileUtils.touch file
      People.new
    end
  end
  
  def store file
    File.open file, 'w' do |f|
      f.write Marshal.dump self
    end
  end

  def marshal_dump
    [@numbers, @persons]
  end

  def marshal_load ary
    @numbers, @persons = ary
  end
  
end
