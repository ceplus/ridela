
require 'test/unit'
require 'ridela.rb'
require 'ridela/vce.rb'

class LanguageTest < Test::Unit::TestCase
  def test_build_with
    b = Ridela::Language.new(Ridela::NamespaceNode.new(:root))
    i = b.interface(:Hello) do
      self.class.class_eval{ include Test::Unit::Assertions }
      assert_equal(2, depth)        
      assert_kind_of(Ridela::NamespaceNode, root)
      assert_kind_of(Ridela::InterfaceNode, that)
      assert_equal(:Hello, that.name)
      method(:foo, :akey=>:aval) do
        assert_equal(3, depth)
        assert_kind_of(Ridela::MethodNode, that)
        assert_equal(:foo,  that.name)
        assert_equal(:aval, that[:akey])
        args([:i, :int], [:j, :string])
      end
    end
    
    assert_kind_of(Ridela::InterfaceNode, i)
    assert_kind_of(Ridela::NamespaceNode, b.that)
    assert_equal(1, b.depth)
    
    ns = b.root
    assert_equal(ns.interfaces.size, 1)
    assert_equal(ns.interfaces[0].name, :Hello)
    assert_equal(ns.interfaces[0].methods.size, 1)
    assert_equal(ns.interfaces[0].methods[0].name, :foo)
    assert_equal(ns.interfaces[0].methods[0].args.size, 2)
    assert_equal(ns.interfaces[0].methods[0].args[0].name, :i)
    assert_equal(ns.interfaces[0].methods[0].args[0].kind.name, :int)
    
    ns[:anon_key] = 'anon_val'
    assert_equal('anon_val', ns[:anon_key])
  end
  
  def test_scope_external
    b = Ridela::Language.new(Ridela::NamespaceNode.new(:root))
    assert_equal(b.resolution, :internal)
    b.with_resolution(:external) do
      i = b.interface(:Hello) do |bb|
        assert_equal(bb, b)
        assert_equal(b.resolution, :external)
      end
    end
    assert_equal(b.resolution, :internal)
  end
  
  def test_message_and_field
    hello = Ridela::namespace(:hello) do
      message(:Hello) do
        field(:foo, :string)
        field(:bar, :int)
      end
    end
    
    assert_equal(hello.messages.size, 1)
    assert_equal(hello.messages.first.name, :Hello)
    assert_equal(hello.messages.first.fields.size, 2)
    assert_equal(hello.messages.first.fields.first.name, :foo)
    assert_equal(hello.messages.first.fields.first.kind.name, :string)
  end
  
  def test_list_kind
    hello = Ridela::namespace(:hello) do
      message(:Hello) do
        field(:foo, list(:string))
      end
    end
    
    target = hello.messages.first.fields.first.kind
    assert_equal("list[string]", target.name)
    # VCE extension
    assert_equal("std::vector< std::string >", target.cxx_name)
  end

  def test_assoc_kind
    hello = Ridela::namespace(:hello) do
      message(:Hello) do
        field(:foo, assoc(:string, :int))
      end
    end
    
    target = hello.messages.first.fields.first.kind
    assert_equal("assoc[string,int]", target.name)
    # VCE extension
    assert_equal("std::map< std::string, vce::VSint32 >", target.cxx_name)
  end

end

class HelloTest < Test::Unit::TestCase
  def test_true
    assert(true)
  end
  
  def test_hello
    ns = Ridela.namespace {
    }
  end
end

