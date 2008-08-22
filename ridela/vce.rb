
require 'ridela/model'
require 'erb'
require 'cgi'

RIDELA_VCE_TEMPLATE = <<EOF
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
      my:type="<%=h template.type %>"
      my:size="<%=h template.size %>" />
<% end %>
<% interface.methods.each do |method| %>
    <method methname="<%= method.name %>" prflow="<%= method[:prflow] %>">
<%   method.args.each do |arg| %>
      <param prtype="<%= t arg.type %>" prname="<%= arg.name %>" />
<%   end %>
    </method>
<% end %>
  </protocol>
</gen>
EOF

module Ridela
  
  #
  # model for <my:template>:
  # we use class instead of annotation
  # because template has some structure
  #
  class TemplateNode
    include Annotatable
    attr_reader :name, :type, :size
    
    def initialize(name, type, size)
      @name = name
      @type = type
      @size = size
    end
  end
  
  #
  # extend interface to support TemplateNode
  #
  class InterfaceNode
    attr_reader :templates
    def templates
      @templates ||= []
      @templates
    end
    
    def children() []; end
  end

  class Language
    def template(name, type, size) that.templates << TemplateNode.new(name, type, size) end
  end
  
  module VCE
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
        when MethodNode
        when ArgNode
        else
          raise "#{node.class} does not supported"
        end
      end
    end
    
    class Writer
      attr_reader :namespace, :interface

      TYPE_MAP = { 
        :long => :dword
      }
      
      def initialize(namespace)
        # VCE::Writer only support namespace with single interface
        @namespace = namespace
        @interface = namespace.interfaces[0]
        Validator.new.set_default_annotation(namespace)
      end
      
      def h(str) CGI.escapeHTML(str); end

      def map_type(src) TYPE_MAP[src] || src; end
      
      def write(out)
        out.write(ERB.new(RIDELA_VCE_TEMPLATE).result(binding).gsub(/\n+/, "\n"))
      end
      
      alias t map_type
    end
  end
end
