
module Ridela

  module Annotatable
    def [](key) (@annotation ||= {})[key]; end
    def []=(key, val)(@annotation ||= {})[key] = val; end
  end
  
  class ArgNode
    include Annotatable
    attr_reader :name, :type
    
    def initialize(name, type)
      @name = name
      @type = type
    end
    
    def children() []; end
  end

  class MethodNode
    include Annotatable
    attr_reader :name, :type, :args
    alias children args
    
    def initialize(name)
      @name = name
      @args = []
      @type = :void
    end

    def add(child)
      @args << child
    end
  end

  class InterfaceNode
    include Annotatable
    attr_reader :name, :methods
    alias children methods
    
    def initialize(name)
      @name    = name
      @methods = []
    end
    
    def add(child)
      @methods << child
    end
  end

  class NamespaceNode
    include Annotatable
    attr_reader :name, :interfaces
    alias children interfaces
    
    def initialize(name)
      @name = name
      @interfaces = []
    end
    
    def add(child)
      @interfaces << child
    end
  end
end
