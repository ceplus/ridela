
require 'ridela'
require 'ridela/vce'

ns = Ridela::namespace(:hello) do
  interface(:DemoProtocol) do
    template('SQLDataMap', 'std::map<std::string>, ws::Variant>', 'ws::MaxSQLDataMapByte')
    template('SQLDataList', 'std::vector<ws::SQLDataMap>', 'ws::MaxSQLDataListByte')
    method(:Say, :flow=>:s2c) do
      args([:message, :string, {:length => 256}], [:count, :int]) 
    end
    that[:cppheader] =<<EOF
#include <wsnetcore/Define.h>
#include <wsnetcore/Serialize.h>
EOF
  end
  
  message(:Hello) do
    field(:foo, :int)
    field(:bar, :string)
  end
  
  message(:Bye) do
    field(:hello, message(:Hello))
    field(:ok, :bool)
  end  
end

out = STDOUT
Ridela::VCE::IDLWriter.new(ns).write(out)
out.print "\n"
Ridela::VCE::CxxMessageWriter.new(ns).write(out)
