
require 'ridela'
require 'ridela/vce'

ns = Ridela::namespace(:hello) do |l|
  l.interface(:DemoProtocol) do
    l.template('SQLDataMap', 'std::map<std::string>, ws::Variant>', 'ws::MaxSQLDataMapByte')
    l.template('SQLDataList', 'std::vector<ws::SQLDataMap>', 'ws::MaxSQLDataListByte')
    l.method(:Say, :prflow=>:s2c) do 
      l.arg(:message, :string, {:prlength => 256})
      l.arg(:count, :int)
    end
    l.that[:cppheader] =<<EOF
#include <wsnetcore/Define.h>
#include <wsnetcore/Serialize.h>
EOF
  end
end

out = STDOUT
Ridela::VCE::Writer.new(ns).write(out)
