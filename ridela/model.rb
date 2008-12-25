
module Ridela

  module Annotatable
    def [](key) (@annotation ||= {})[key]; end
    def []=(key, val)(@annotation ||= {})[key] = val; end
  end
  
  module Parentable
    def add(child)
      children << child
    end
  end
  
  class DataNode
    include Annotatable
    attr_reader :name, :kind
    
    def initialize(name, kind)
      @name = name
      @kind = kind
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
