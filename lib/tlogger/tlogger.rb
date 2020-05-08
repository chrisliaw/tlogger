
require 'logger'
require 'openssl'

module Tlogger

  ##
  # Tlogger class is meant to be a thin wrapper around the Ruby Logger class (by default) to provide contextual logging capabilities to the logging system.
  #
  # Contextual logging allow developers:
  # * Structure the log message not only by the severity (debug, info, error, warning) but also another key that is useful for the application
  #   during troublehshooting purposes. This can provide more info to the log message being logged. For example can automatically tag the log 
  #   message with number of 1789 loops in the program
  # * Subsequent from this context info, developer now can selectively turn on / off certain logging message to get the clarity needed. Relying
  #   on the above example, if we are only interested in loop 1232, we can disabled all other log message EXCEPT the tag show loop_1232. 
  #   This will drastically reduce the effort required in reading all the 1231 lines of log. 
  #
  # I found it rather helpful especially in managing the print out of log AFTER it has been logging from everywhere in my programs. 
  # I also found that just filtering by log level (debug, info, error and warn) is not sufficient sometime to lessen the effort of log reading 
  # for a specific issue especially the only way to debug is turned on the debug level and ALL debug messages now sprang to life! 
  # It is really not an easy task to look for specific info especially when it was an old project.
  #
  # Now you can just disable all and only turn on the specific tag around the issue area to investigate the issue. You will now have better focus
  # in the issue on hand instead of hunting the line that you need from long list of debug output.
  class Tlogger

    # +tag+ is the tag that is being set for this logger session.
    # 
    # One session shall only have one specific tag value, which is the default tag for this logger session.
    # 
    # If multiple tags are required, use the method tdebug, terror, twarn, tinfo or #with_tag block to create a new tag
    #
    # Note that the tag can be in symbol or string, however shall convert to symbol when processing
    attr_accessor :tag 
    # +include_caller+ (true/false) tell the logger to print the caller together with the tag 
    attr_accessor :include_caller
    # +logger+ it is the actual logger instance of this Tlogger
    attr_reader :logger

    def initialize(*args , &block)
      # default to console
      if args.length == 0
        args << STDOUT
      end

      @opts = {}
      if args[-1].is_a?(Hash)
        @opts = opts
        @opts = { } if @opts.nil?
        args = args[0..-2]
      end

      @logger = @opts[:logger_instance] || Logger.new(*args,&block)
      @disabled = []
      @dHistory = {}
      @include_caller = false
      @tag = nil

      @genable = true
      @exception = []
    end # initialize

    # 
    # :method: with_tag
    #
    # Tag all log inside the block with the given tag value
    #
    # Useful to tag multiple lines of log under single tag
    #
    def with_tag(tag,&block)
      if block and not tag.nil?
        log = self.clone
        log.tag = tag
        block.call(log)
      end
    end # with_tag

    # 
    # :method: off_tag
    #
    # Turn off a tag. After turning off, the log message that tie to this tag shall not be printed out
    #
    # Do note that all tags by default are turned on.
    #
    def off_tag(*tags)
      tags.each do |tag|
        if not (tag.nil? or tag.empty? or @disabled.include?(tag))
          @disabled << tag.to_sym
        end
      end
    end # off_tag
    alias_method :tag_off, :off_tag

    #
    # :method: on_tag
    #
    # Turn on a tag. 
    #
    # Note that by default all tags are turned on. This only affect whatever tags that has been turned off via 
    # the method #off_tag. It doesn't work as adding a tag. Adding a tag message should use tdebug, terror, tinfo,
    # twarn or #with_tag
    def on_tag(*tags)
      tags.each do |tag|
        @disabled.delete(tag.to_sym) if not (tag.nil? or tag.empty?)
      end
    end # on_tag
    alias_method :tag_on, :on_tag

    # 
    # :method: off_all_tags
    #
    # All log messages with tag out of your face!
    #
    def off_all_tags
      @genable = false
      clear_exceptions
    end
    alias_method :all_tags_off, :off_all_tags
    alias_method :tags_all_off, :off_all_tags

    #
    # :method: on_all_tags
    #
    # All log messages now come down on you! RUN!
    # 
    # No wait, you need to read that before you run away...
    #
    def on_all_tags
      @genable = true
      clear_exceptions
    end
    alias_method :all_tags_on, :on_all_tags
    alias_method :tags_all_on, :on_all_tags

    # 
    # :method: off_all_tags_except
    # 
    # Turn off all tags EXCEPT the tags given.
    #
    # Note the parameters can be a list (multiple tags with ',' separator)
    #
    def off_all_tags_except(*tags)
      off_all_tags
      clear_exceptions
      @exception.concat tags.map(&:to_sym)  
    end
    alias_method :off_all_except, :off_all_tags_except
    alias_method :all_off_except, :off_all_tags_except

    # 
    # :method: on_all_tags_except
    #
    # Turn on all tags EXCEPT the tags given
    #
    # Note the parameters can be a list (multiple tags with ',' separator)
    #
    def on_all_tags_except(*tags)
      on_all_tags
      clear_exceptions
      @exception.concat tags.map(&:to_sym)
    end
    alias_method :on_all_except, :on_all_tags_except
    alias_method :all_on_except, :on_all_tags_except

    # 
    # :method: clear_exceptions
    #
    # Clear the exception list. All exampted tags given either by #off_all_tags_except or #on_all_tags_except 
    # shall be reset
    #
    def clear_exceptions
      @exception.clear
    end

    # 
    # :method: remove_from_exception
    #
    # Remote a set of tags from the exception list
    #
    def remove_from_exception(*tags)
      @exception.delete_if { |e| tags.include?(e) }
    end

    # 
    # :method: method_missing
    #
    # This is where the delegation to the Logger object happen or no_method_exception shall be thrown
    #
    def method_missing(mtd, *args, &block)
      if [:debug, :error, :info, :warn].include?(mtd)
      
        if args.length > 0 and args[0].is_a?(Symbol)
          tag = args[0]
          args = args[1..-1]
        else
          tag = @tag
        end 
        
        if is_genabled?(tag) and not tag_disabled?(tag) 

          if block
            if not (tag.nil? or tag.empty?) and args.length == 0 
              args = [ format_message(tag) ]
            end

            out = block
          else
            if not (tag.nil? or tag.empty?)
              str = args[0]
              args = [ format_message(tag) ]
              out = Proc.new { str }
            else
              out = block
            end
          end

          @logger.send(mtd, *args, &out)

        end # if not disabled


      elsif [:tdebug, :terror, :tinfo, :twarn].include?(mtd)
       
        key = args[0]
       
        if is_genabled?(key) and not tag_disabled?(key.to_sym)
          if block
            out = Proc.new { block.call }
            args = [ format_message(args[0]) ]
          else
            str = args[1]
            out = Proc.new { str }
            args = [ format_message(args[0]) ]
          end

          mtd = mtd.to_s[1..-1].to_sym
          @logger.send(mtd, *args, &out)
        end

      elsif [:odebug, :oerror, :oinfo, :owarn].include?(mtd)

        key = args[0]

        if is_genabled?(key) and not tag_disabled?(key)

          if block
            out = Proc.new { block.call }
            args = [ format_message(args[0]) ]
          else
            str = args[1]
            out = Proc.new { str }
            args = [ format_message(args[0]) ]
          end

          msg = out.call
          if not (msg.nil? or msg.empty?) 
            if not already_shown_or_add(key,msg)
              mtd = mtd.to_s[1..-1].to_sym
              @logger.send(mtd, *args, &out)
            end
          end

        end

      elsif @logger.respond_to?(mtd)
        @logger.send(mtd, *args, &block)
      else
        super
      end
    end # method_missing

    # 
    # :method: tag_disabled?
    #
    # Check if the tag is disabled
    #
    def tag_disabled?(tag)
      if tag.nil? or tag.empty?
        false
      else
        @disabled.include?(tag.to_sym)
      end
    end

    #
    # :method: show_source
    # Helper setting the flag include_caller
    #
    def show_source 
      @include_caller = true
    end

    private
    def format_message(key)
      # returning args array
      if @include_caller
        "[#{key}] #{find_caller} "
      else
        "[#{key}] "
      end 
    end

    def is_genabled?(key)
      if key.nil?
        true
      else
        (@genable and not @exception.include?(key.to_sym)) or (not @genable and @exception.include?(key.to_sym))
      end
    end

    def already_shown_or_add(key,msg)
      smsg = Digest::SHA256.hexdigest(msg)
      if @dHistory[key.to_sym].nil?
        add_to_history(key,smsg)
        false
      else
        res = @dHistory[key.to_sym].include?(smsg)
        add_to_history(key,smsg) if not res
        res
      end
    end # already_shown_or_add

    def add_to_history(key,dgt)
      @dHistory[key.to_sym] = [] if @dHistory[key.to_sym].nil?
      @dHistory[key.to_sym] << dgt if not @dHistory[key.to_sym].include?(dgt)
    end # add_to_history

    def find_caller
      caller.each do |c|
        next if c =~ /tlogger.rb/
        @cal = c
        break
      end

      if @cal.nil? or @cal.empty?
        @cal = caller[0] 
      end 
     
      # reduce it down to last two folder?
      sp = @cal.split(File::SEPARATOR)
      if sp.length > 1
        msg = "/#{sp[-2]}/#{sp[-1]}" 
      else
        msg = sp[-1]
      end
      
      msg
      
    end # find_caller

  end
end
