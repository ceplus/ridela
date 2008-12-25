
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
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
  end

  class ListKind
    include Kind
    attr_reader :element_kind
    
    def initialize(ek)
      @element_kind = ek
    end
    
    def name
      "list[#{@element_kind.name}]"
    end
  end

  class AssocKind
    include Kind
    attr_reader :key_kind, :value_kind
    
    def initialize(kk, vk)
      @key_kind = kk
      @value_kind = vk
    end
    
    def name
      "assoc[#{@key_kind.name},#{@value_kind.name}]"
    end
  end
  
  class ListKind
    include Kind
    attr_reader :element_kind
    
    def initialize(ek)
      @element_kind = ek
    end
      
    def name
      "list[#{@element_kind.name}]"
    end
  end

  class NodeKind
    include Kind
    attr_reader :node
    
    def initialize(node)
      @node = node
    end
    
    def name() node.name; end
  end
  
  def self.kindify(kind)
    if kind.class.include?(Kind)
      kind
    elsif /Node$/ =~ kind.class.name
      NodeKind.new(kind)
    else
      case kind
      when Symbol
        PrimitiveKind.new(kind)
      when PrimitiveKind
        kind
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
