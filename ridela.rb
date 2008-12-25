
require 'ridela/model'
require 'ridela/language'

if __FILE__ == $0
  require 'ridela/driver'
  Ridela::Driver.new(ARGV).run
end
