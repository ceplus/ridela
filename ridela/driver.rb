
require 'ridela/model'
require 'ridela/language'
require 'ridela/vce'
require 'optparse'

module Ridela
  class Driver
    
    WRITERS = { 
      'gen-idl' => VCE::IDLWriter,
      'vce-message-cxx-h' => VCE::CxxMessageWriter
    }
    
    attr_reader :module_filename, :writer_name, :src, :dst
    
    def initialize(argv)
      @will = :write
      parse_argv(argv)
    end
    
    def parse_argv(argv)
      OptionParser.new do |opts|
        opts.on_tail("-h", "--help", "Show this message") { puts opts }
        opts.on("-d FILE", "--dst FILE", "Output filename") { |x| @dst = x }
        opts.on("-s FILE", "--src FILE", "Input filename") { |x| @src = x }
        opts.on("-w TYPE", "--writer TYPE", "Writer type") { |x| self.writer_name = x }
        opts.on("-l", "--list", "list writer types") { @will = :list }
      end.parse!(argv)
      @src ||= argv[0]
    end
    
    def writer_name=(x)
      raise "Unknown writertype: #{x}" unless WRITERS.include?(x)
      @writer_klass = WRITERS[x]
    end
    
    def run
      case @will
      when :list
        list_write_types
      when :write
        write
      else
        raise "Unknown will: #{@will}"
      end
    end
    
    def list_write_types
      puts "writer types:\n"
      WRITERS.keys.each do |k|
        puts "  #{k}\n"
      end
    end

    def write
      ns = load_module(open(@src))
      @writer_klass.new(ns).write(open_dst)
    end
    
    private
    
    def load_module(io)
      eval(io.read)
    end
    
    def open_dst
      return open(@dst, 'w') if @dst
      STDOUT
    end
  end
  
  
end
