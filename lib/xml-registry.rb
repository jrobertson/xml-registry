#!/usr/bin/ruby

# file: xml-registry.rb

require 'rexml/document'
include REXML

class XMLRegistry

  def initialize()
    super()
    @template = '<root><system/><app/><user/><ip_address/></root>'
    @doc = Document.new(@template)
  end

  def initialise_registry()
    @doc = Document.new(@template)
  end

  alias :reset_registry :initialise_registry

  def set_key(path, value)
    create_path = find_path(path)  
    
    if not create_path.empty? then
      parent_path = (path.split('/') - create_path.reverse).join('/')
      key_builder(parent_path, create_path)
    end
    
    add_value(path, value)  
  end

  def get_key(path)
    XPath.first(@doc.root, path)
  end

  def delete_key(path)
    node = XPath.first(@doc.root, path)
    node.parent.delete node if node
  end

  def to_xml()
    @doc.to_s
  end

  alias :display_xml :to_xml

  def load_xml(s='')  
    @doc = Document.new(read(s))	  
  end

  def save(s)
    File.open(s){|f| @doc.write f}
  end

  def import(s)      
    reg_buffer = read(s)

    reg_items = reg_buffer.gsub(/\n/,'').split(/(?=\[.[^\]]+\])/).map do |x| 
      [x[/^\[(.[^\]]+)\]/,1], Hash[*($').scan(/"([^"]+)"="(.[^"]+)?"/).flatten]]
    end

    reg_items.each do |path, items|
      items.each {|k,value| self.set_key("%s/%s" % [path,k], value)}
    end
  end

  def export(s=nil)
    reg = print_scan(@doc.root).join("\n")
    File.open(s){|f| f.write reg} if s
    reg
  end

  private

  def add_key(path='app', key='untitled')
    node = @doc.root.elements[path] 
    node.add_element Element.new(key)
  end

  def add_value(key, value)
    @doc.root.elements[key].text = value
  end

  def find_path(path, create_path=[])
    return create_path if @doc.root.elements[path]
    apath = path.split('/')
    create_path << apath.pop
    find_path(apath.join('/'), create_path)
  end

  def key_builder(parent_path, create_path)
    key = create_path.pop
    add_key(parent_path, key)
    key_builder("#{parent_path}/#{key}", create_path) unless create_path.empty?
  end

  def read(s)
    if s[/^https?:\/\//] then
      buffer = open(s, "UserAgent" => "Ruby Registry-reader").read
    elsif File.exists? s then
      buffer = File.open(s).read
    else
      buffer = s
    end
  end

  def print_scan(node, parent=[])
    out = []
    parent << node.name 
    items = []
    node.elements.each do |e|
      if e.has_elements? then
        out << print_scan(e, parent.clone) 
      else
        items << [e.name, e.text]
      end
    end  
    if parent.length > 1 and items.length > 0 then
      out << "[%s]\n%s\n" % [parent[1..-1].join("/"), 
                            items.map {|x| "\"%s\"=\"%s\"" % x}.join("\n")]    
    end
    out  
  end

end


