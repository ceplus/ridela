
module Ridela

  module Annotatable
    def [](key) (@annotation ||= {})[key]; end
    def []=(key, val)(@annotation ||= {})[key] = val; end
  end
  
  module Parentable
    def add(child)
      children << child
    end
    
    def find(name)
      children.find{ |c| c.name == name }
    end
  end

  module Kind
    # open-mixin: external code can hook-up kind classes
  end
  
  class PrimitiveKind
    include Kind
    attr_reader :name, :bytes
    
    @@builtins = {}
    
    def initialize(name, bytes)
      @name  = name
      @bytes = bytes
    end

    def self.find(name) @@builtins[name]; end
    def self.define(name, bytes) @@builtins[name] = self.new(name, bytes); end
  end

  PrimitiveKind.define(:int, 4)
  PrimitiveKind.define(:uint, 4)
  PrimitiveKind.define(:bool, 1)
  
  class TextKind # string
    DEFAULT_BYTES = 32
    
    include Kind
    attr_reader :bytes
    def name() :text; end
    def initialize(b=DEFAULT_BYTES)
      @bytes = b
    end
  end
  
  class ListKind
    DEFAULT_LIMIT = 16
    include Kind
    attr_reader :element_kind, :limits
    
    def initialize(ek, li)
      @element_kind = ek
      @limits = li
    end
    
    def name() "list[#{@element_kind.name}]"; end
    def bytes() limits*(@element_kind.bytes); end
  end

  class AssocKind
    DEFAULT_LIMIT = 16
    include Kind
    attr_reader :key_kind, :value_kind, :limits
    
    def initialize(kk, vk, li)
      @key_kind = kk
      @value_kind = vk
      @limits = li
    end
    
    def name() "assoc[#{@key_kind.name},#{@value_kind.name}]"; end
    def bytes() limits*(@key_kind.bytes + @value_kind.bytes); end
  end
  
  class MessageKind
    include Kind
    attr_reader :node
    
    def initialize(node)
      @node = node
    end
    
    def name() node.name; end
    def bytes() node.children.inject(0) { |a, c| a + c.kind.bytes }; end
  end
  
  def self.kindify(kind)
    if kind.class.include?(Kind)
      kind
    else
      case kind
      when MessageNode
        MessageKind.new(kind)
      when :string # for backward compatibility: use text()
        TextKind.new
      when Symbol
        PrimitiveKind.find(kind)
      else
        raise "Unknown Kind:#{kind}" 
      end
    end
  end
  
  class DataNode
    include Annotatable
    attr_reader :name, :kind
    
    def initialize(name, kind)
      @name = name
      @kind = Ridela.kindify(kind)
    end
    
    def children() []; end
  end

  class ArgNode < DataNode; end
  
  class MethodNode
    include Annotatable
    attr_reader :name, :kind, :args
    alias children args
    
    def initialize(name)
      @name = name
      @args = []
      @kind = :void
    end

    def add(child)
      @args << child
    end
  end

  class InterfaceNode
    include Annotatable, Parentable
    attr_reader :name, :methods
    alias children methods
    
    def initialize(name)
      @name    = name
      @methods = []
    end
  end

  class MessageNode
    include Annotatable, Parentable
    attr_reader :name, :fields
    alias  children fields
    
    def initialize(name)
      @name   = name
      @fields = []
    end
  end
  
  class FieldNode < DataNode; end
  
  # XXX: support namespace nesting
  class NamespaceNode
    include Annotatable, Parentable
    attr_reader :name, :children
   
    def initialize(name)
      @name = name
      @children = []
    end

    def interfaces() @children.select{ |i| i.kind_of?(InterfaceNode) }; end
    def messages() @children.select{ |i| i.kind_of?(MessageNode) }; end
  end
end
