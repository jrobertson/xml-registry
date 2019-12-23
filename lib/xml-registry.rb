#!/usr/bin/env ruby

# file: xml-registry.rb

#require 'rexle'
#require 'rxfhelper'
require 'simple-config'


module NumberCheck
  
  refine String do
    
    def is_number?
      self.to_i.to_s == self
    end
    
  end
end

class XMLRegistry
  using NumberCheck

  attr_reader :doc
  
  def initialize(template = '<root></root>', debug: false)
    
    @debug = debug
    super()
    @template, _ = RXFHelper.read(template)
    @doc = Rexle.new(@template)
  end

  # Creates a new registry document from scratch. Optional param: string XML template
  # example: initialise_registry('<root><app/></root>')
  #
  def initialise_registry(new_template=nil)
    @doc = Rexle.new(new_template || @template)
  end

  alias :reset_registry :initialise_registry
  alias :initialize_registry :initialise_registry

  # Set the key by passing in the path and the value
  # example: set_key 'app/gtd/funday', 'friday'
  #
  def set_key(path, value)

    # if the 1st element doesn't exist create it
    e = path.split('/',2).first
    @doc.root.add_element Rexle::Element.new(e) unless @doc.root.element e
    create_path = find_path(path)  

    if not create_path.empty? then
      parent_path = (path.split('/') - create_path.reverse).join('/')
      key_builder(parent_path, create_path)
    end
    
    add_value(path, value)  
  end

  def []=(path, val)
    s = path.split('/').map {|x| x[0].is_number? ? x.prepend('x') : x}.join '/'
    self.set_key(s, val)
  end
  
  # get the key value by passing the path
  # example: get_key('app/gtd/funday').value #=> 'friday'
  #
  # returns the value as a Rexle::Element
  #
  def get_key(path)

    key = @doc.root.element path
    raise ("xml-registry: key %s not found" % path) unless key
    
    key.instance_eval { 
      @path = path 

      def to_h(e)

        v = if e.has_elements? then 
          e.elements.inject({}) do |r, x|
            r.merge to_h(x)
          end
        else
          e.text
        end

        {e.name => v}
      end    
    
      def to_config()                    
        SimpleConfig.new(to_h(self), attributes: {key: @path})
      end    
    
      def to_kvx()                    
        Kvx.new(to_h(self), attributes: {key: @path})
      end        
    
      def to_os()
        OpenStruct.new(to_h(self).first.last)
      end
    }
    
    key
  end
  
  # get several keys using a Rexle XPath
  # example: get_keys('//funday') #=> [<funday>tuesday</funday>,<funday>friday</funday>]
  #
  # returns an array of 0 or more Rexle elements
  #
  def get_keys(path)
    @doc.root.xpath(path)
  end        

  def [](path)
    s = path.split('/').map {|x| x.is_number? ? x.prepend('x') : x}.join '/'
    @doc.root.element s
  end

  # delete the key at the specified path
  # example: delete_key 'app/gtd/funday'
  #
  #
  def delete_key(path)
    @doc.root.delete path    
  end

  # return the registry as an XML document
  # example: puts reg.to_xml pretty: true
  #
  def to_xml(options={})
    @doc.xml options
  end

  alias :display_xml :to_xml
  
  def xml(options={})
    @doc.root.xml options
  end  

  # load a new registry xml document replacing the existing registry
  #
  def load_xml(s='')      
    @doc = Rexle.new(RXFHelper.read(s)[0])          
    self
  end

  # save the registry to the specified file path
  #
  def save(s)
    RXFHelper.write s, @doc.xml(pretty: true)
  end

  # import a registry hive from a string in registry format
  #
  # example:
  #
  #s =<<REG
#[app/app1]
#"admin"="jrobertson"
#"pin-no"="1234"
#
#[app/app2]
#"admin"="dsmith"
#"pin-no"="4321"
#REG
#
#reg = XMLRegistry.new 
#reg.import s 
  #
  def import(s)      
    
    r = RXFHelper.read(s)
    reg_buffer = r.first
    raise "read file error" unless reg_buffer

    if  reg_buffer.strip[/^\[/] then

      reg_items = reg_buffer.gsub(/\n/,'').split(/(?=\[.[^\]]+\])/).map do |x| 
        [x[/^\[(.[^\]]+)\]/,1], Hash[*($').scan(/"([^"]+)"="(.[^"]*)"/).flatten]]
      end
      
    elsif reg_buffer.strip.lines.grep(/^\s+\w/).any? 

      puts 'hierachical import' if @debug
      doc = LineTree.new(reg_buffer).to_doc
      
      reg_items = []
      
      doc.root.each_recursive do |e|
        
        puts 'e: ' + e.inspect if @debug
        if e.is_a?(Rexle::Element) and e.children.length < 2 then
          
          reg_items << [e.backtrack.to_xpath.sub(/^root\//,'')\
                        .sub(/\/[^\/]+$/,''), {e.name => e.text }]
          
        end
          
      end      
      
    else

      reg_items = reg_buffer.split(/(?=^[^:]+$)/).map do |raw_section|

        lines = raw_section.lines.to_a
        next if lines.first.strip.empty?
        path = lines.shift.rstrip
        [path, Hash[lines.map{|x| x.split(':',2).map(&:strip)}]]
      end
      
      reg_items.compact!
      
    end

    puts 'reg_items: ' + reg_items.inspect if @debug
    reg_items.each do |path, items|
      items.each {|k,value| self.set_key("%s/%s" % [path,k], value)}
    end
    
    :import
  end

  # Export the registry to file if the filepath is specified. Regardless, 
  # the registry will be returned as a string in the registry 
  # export format.
  #
  def export(s=nil)
    reg = print_scan(@doc.root).join("\n")
    # jr 250118 File.open(s){|f| f.write reg} if s
    RXFHelper.write(s, reg) if s
    reg
  end

  def xpath(s)
    @doc.root.xpath s
  end

  private

  def add_key(path='app', key='untitled')
    node = @doc.root.element path
    r = node.add_element Rexle::Element.new(key)
    r
  end

  def add_value(key, value)
    @doc.root.element(key).text = value
  end

  def find_path(path, create_path=[])

    return create_path if !@doc.root.xpath(path).empty?
    apath = path.split('/')
    create_path << apath.pop
    find_path(apath.join('/'), create_path)
  end

  def key_builder(parent_path, create_path)
    key = create_path.pop
    add_key(parent_path, key)
    key_builder("#{parent_path}/#{key}", create_path) unless create_path.empty?
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
