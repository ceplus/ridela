
require 'ridela/model'
require 'erb'
require 'cgi'

RIDELA_VCE_XML_TEMPLATE = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<gen xmlns:my="http://vce.ce-lab.net/2007/my">
  <protocol name="<%= interface.name %>"
            recvprefix="<%= interface[:recvprefix] %>"
            sendprefix="<%= interface[:sendprefix] %>">
    <config debuglog="<%= interface[:config_debuglog] %>"
            dummyproto="<%= interface[:config_dummyproto] %>"
            hashid="<%= interface[:config_hasid] %>"
            mpi="<%= interface[:mpi] %>"
            structparameter="<%= interface[:config_structparameter] %>"/>
    <shuffle seed="<%= interface[:shuffle_seed] %>" />
    <cppheader>
<%=h interface[:cppheader] %>
</cppheader>
    <includepath incpath="<%=h interface[:incpath] %>" />
<% interface.templates.each do |template| %>
    <my:template my:tempname="<%= template.name %>"
      my:type="<%=h template.kind.cxx_name %>"
      my:size="<%=h template.size %>" />
<% end %>
<% interface.methods.each do |method| %>
    <method methname="<%= method.name %>" prflow="<%= method[:flow] %>">
<% method.args.each do |arg| %>
      <param prtype="<%= arg.kind.cxx_name %>" prname="<%= arg.name %>" <%= prlength(arg) %> />
<%   end %>
    </method>
<% end %>
  </protocol>
</gen>
EOF

RIDELA_VCE_CXX_MESSAGE_TEMPLATE = <<EOF
#ifndef <%= guard_name %>_H
#define <%= guard_name %>_H
 
/*
 * generated automatically: do not edit!
 */
#include <vce2serialize.h>

namespace <%= namespace.name %>
{
 
<% namespace.messages.each do |m| %>
  class <%= m.name %>
  {
  public:
    <%= m.name %>()
      : <%= m.fields.map {|f| f.cxx_initer_zero }.select{|i| i }.join(', ') %> {}
    <%= m.name %>(<%= m.fields.map {|f| f.cxx_in_arg_decl }.join(', ') %>)
      : <%= m.fields.map {|f| f.cxx_initer_assign }.join(', ') %> {}  
   
<% m.fields.each do |field| %>
    const <%= field.kind.cxx_name %>& Get<%= field.name.to_s.capitalize %>() const { return <%= field.name %>; }
    <%= field.kind.cxx_name %>& Get<%= field.name.to_s.capitalize %>() { return <%= field.name %>; }
    void Set<%= field.name.to_s.capitalize %>(const <%= field.kind.cxx_name %>& val0) { <%= field.name %> = val0; }
<% end %>
  private:
<% m.fields.each do |field| %>
    <%= field.kind.cxx_name %> <%= field.name %>;
<% end %>
  };
 
<% end %>
} // <%= namespace.name %>
 
namespace vce_gen_serialize
{

<% namespace.messages.each do |m| %>
  template<class Buffer>
  bool Push(const <%= m.name %>& message, Buffer& buffer);
  template<class Buffer>
  bool Pull(<%= m.name %>& message, Buffer& buffer);
<% end %>
 
<% namespace.messages.each do |m| %>
  inline bool Push(const <%= m.name %>& message, Buffer& buffer)
  {
<% m.fields.each do |f| %>
    if (Push(message.Get<%= f.name.to_s.capitalize %>(), buffer)) { return false; }
<% end %>
    return true;
  }
 
  template<class Buffer>
  inline bool Pull(<%= m.name %>& message, Buffer& buffer)
  {
<% m.fields.each do |f| %>
    if (Pull(message.Get<%= f.name.to_s.capitalize %>(), buffer)) { return false; }
<% end %>
    return true;
  }
 
<% end %>
} // vce_gen_serialize

#endif//<%= guard_name %>_H
EOF

module Ridela

  module VCE
    #
    # model for <my:template>:
    # we use class instead of annotation
    # because template has some structure
    #
    class TemplateKind < Struct.new(:name)
      include Ridela::Kind
      def compound?() false; end
    end
    
    class TemplateNode
      include Annotatable
      attr_reader :name, :kind, :size
      
      def initialize(name, kind, size)
        @name = name
        @kind = TemplateKind.new(kind)
        @size = size
      end
    
      def compound?() false end
    end
    
    class CxxKind < Struct.new(:name, :size, :initer); end
    
    class Validator
      def initialize
        @mpi = 1000
      end
      
      def set_default_annotation(node)
        node.children.each { |c| set_default_annotation(c) }
        case (node)
        when NamespaceNode
        when InterfaceNode
          node[:recvprefix] ||= 'Recv'
          node[:sendprefix] ||= 'Send'
          node[:config_debuglog]   ||= :true
          node[:config_dummyproto] ||= :true
          node[:config_hashid]     ||= :false
          node[:config_structparameter] ||= :false
          node[:shuffle_seed] ||= ''
          node[:cppheader] ||= ''
          node[:incpath]   ||= './'
          node[:mpi]       ||= (@mpi += 1).to_s
        when MethodNode, ArgNode, MessageNode, FieldNode
        else
          raise "#{node.class} does not supported"
        end
      end
    end

    module WriterHelper
      def h(str) CGI.escapeHTML(str); end
    end
    
    class IDLWriter
      include WriterHelper
      attr_reader :namespace, :interface
      
      def initialize(namespace)
        # VCE::IDLWriter only support namespace with single interface
        @namespace = namespace
        @interface = namespace.interfaces[0]
        Validator.new.set_default_annotation(namespace)
      end
      
      def prlength(arg)
        arg[:length] ? "prlength=\"#{arg[:length]}\"" : ""
      end

      def write(out)
        out.write(ERB.new(RIDELA_VCE_XML_TEMPLATE).result(binding).gsub(/\n+/, "\n"))
      end
    end
    
    class CxxMessageWriter
      attr_reader :namespace
      
      def initialize(namespace)
        @namespace = namespace
      end

      def write(out)
       out.write(ERB.new(RIDELA_VCE_CXX_MESSAGE_TEMPLATE).result(binding).gsub(/\n+/, "\n"))        
      end
      
      def guard_name
        "RIDELA_" + namespace.name.to_s.upcase
      end

    end
    
  end

  module Kind
    @@cxx_builtin_table = {} # Symbol => CxxKind
    def cxx_name
      case self
      when PrimitiveKind
        (@@cxx_builtin_table[self.name] || (raise "Unknown Primitive!:#{self.kind.name}")).name
      else
        # XXX: encode compound name
        self.name
      end
    end
    
    def cxx_initer
      @@cxx_builtin_table.include?(self.name) ? @@cxx_builtin_table[self.name].initer : nil
    end
    
    def self.cxx_builtin(key, name, size, initer)
      @@cxx_builtin_table[key] = VCE::CxxKind.new(name, size, initer)
    end
  end
  
  Kind.cxx_builtin(:int,    'vce::VSint32', nil, '0')
  Kind.cxx_builtin(:uint,   'vce::VUint32', nil, '0')
  Kind.cxx_builtin(:bool,   'bool', 4, 'false')
  Kind.cxx_builtin(:string, 'std::string', 32, nil)
  
  #
  # extend interface to support TemplateNode
  #
  class InterfaceNode
    attr_reader :templates
    def templates() @templates ||= []; end
  end

  class FieldNode
    def cxx_in_arg_decl()
      "const #{kind.cxx_name}& #{cxx_in_arg_name}"
    end
    
    def cxx_in_arg_name()
      "#{name}0"
    end
    
    def cxx_initer_zero
      initer = kind.cxx_initer
      initer ? "#{name}(#{initer})" : nil
    end

    def cxx_initer_assign
      "#{name}(#{cxx_in_arg_name})"
    end
  end
  
  class Language
    def template(name, kind, size) that.templates << VCE::TemplateNode.new(name, kind, size) end
  end
  
end
