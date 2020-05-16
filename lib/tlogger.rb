require "tlogger/version"

require_relative "tlogger/tlogger"
require_relative "tlogger/logger_group"

# 
# :nodoc:
#
module Tlogger
  class Error < StandardError; end

  # shorten the initializer to Tlogger.new instead of the longer Tlogger::Tlogger.new
  class << self
    def new(*args,&block)
      ::Tlogger::Tlogger.new(*args,&block) 
    end
  end # class self

end

