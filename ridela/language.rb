
module Ridela
  
  class Language
    def root() @scope.first; end
    def that() @scope.last; end
    def depth() @scope.size; end
    def resolution() @block_resolutions.last; end
    def push_resolution(resol) @block_resolutions << resol; end
    def pop_resolution() @block_resolutions.pop; end
    
    def initialize(root)
      @scope = [root]
      @block_resolutions = [:internal]
    end
    
    def with_resolution(resol, &block)
      push_resolution(resol)
      begin
        define(block) 
      ensure
        pop_resolution
      end
    end
    
    def args(*arg_list)
      arg_list.each do |a|
        arg(*a)
      end
    end
    
    def define(block)
      case resolution
      when :internal
        instance_eval(&block)
      when :external
        block.call(self)
      else
        raise "Unknown resolution rule!"
      end
    end
   
    def define_with(topush, annotations, block=nil)
      annotations.each { |k,v| topush[k] = v }
      @scope.push(topush)
      begin
        define(block) if block
      ensure
        @scope.pop
        @scope.last.add(topush)
      end
      topush
    end
    
    def interface(name, annot={}, &block)
      define_with(InterfaceNode.new(name), annot, block)
    end
    
    def method(name, annot={}, &block)
      define_with(MethodNode.new(name), annot, block)
    end
    
    def arg(name, kind, annot={})
      define_with(ArgNode.new(name, kind), annot)
    end

    def annotate(key, val)
      @scope.last[key] = val
    end
    
    def message(name, annot={}, &block)
      define_with(MessageNode.new(name), annot, block)
    end
    
    def field(name, kind, annot={})
      define_with(FieldNode.new(name, kind), annot)
    end
  end
  
  def self.namespace(name="", &block)
    l = Language.new(NamespaceNode.new(name))
    l.define(block) if block_given?
    l.root
  end
end
