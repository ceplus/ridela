
require 'test/unit'
require 'ridela.rb'

class LanguageTest < Test::Unit::TestCase
  def test_build_with
    b = Ridela::Language.new(Ridela::NamespaceNode.new(:root))
    i = b.interface(:Hello) do
      type.class_eval{ include Test::Unit::Assertions }
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
    assert_equal(ns.interfaces[0].methods[0].args[0].type, :int)
    
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

