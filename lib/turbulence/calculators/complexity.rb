require 'stringio'
require 'flog'

PARSER_VERSION = RUBY_VERSION.split(".").first(2).join("")
RUBY_PARSER_VERSION = "Ruby#{PARSER_VERSION}Parser"
FLOG_VERSION = "Flog#{PARSER_VERSION}"

unless defined?(RUBY_PARSER_VERSION.to_sym)
  parser_klass = Class.new(RubyParser) do
    def process(ruby, file)
      ruby.gsub!(/(\w+):\s+/, '"\1" =>')
      super(ruby, file)
    end
  end
  Object.const_set(RUBY_PARSER_VERSION, parser_klass)
end

flog_klass = Class.new(Flog) do
  def initialize option = {}
    super(option)
    @parser = Object.const_get(RUBY_PARSER_VERSION).send(:new)
  end
end
Object.const_set(FLOG_VERSION, flog_klass)

class Turbulence
  module Calculators
    class Complexity
      attr_reader :config, :type

      def initialize(config = nil)
        @config = config || Turbulence.config
        @type = :complexity
      end

      def flogger
        @flogger ||= Object.const_get(FLOG_VERSION).send(:new, continue: true)
      end

      def for_these_files(files)
        files.each do |filename|
          yield filename, score_for_file(filename)
        end
      end

      def score_for_file(filename)
        flogger.reset
        flogger.flog filename
        flogger.total_score
      end
    end
  end
end
