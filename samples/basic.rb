

require 'tlogger'

log = Tlogger::Tlogger.new

log.debug "Without tagging"
log.info "Without tagging"
log.warn "Without tagging"
log.error "Without tagging"

# default tag for this loging session
log.tag = "global"

log.debug { "With default tagging" }
log.info { "With default tagging" }
log.warn { "With default tagging" }
log.error { "With default tagging" }

# include the file and location where the log message is printed out
log.include_caller = true
log.tdebug :mytag, "With per log message tagging"

log.with_tag :block_tag do |log|
  log.debug "Inside block"
  log.info "inside block"
  log.warn "inside block"
  log.error "inside block"
end

log.debug "Outside block. Shall take default tag '#{log.tag}'"

log.debug "About to show log message only show once. This can be useful if it is a warning which only print out per run."
(0..4).each do |i|
  # one time message tie to key
  # Means if the message is under specific key and already prompted, it will skip
  # Else it will be printed
  log.odebug  :debug_once, &-> { "this is one time message" }
  log.oerror  :error_once,  "One time error"
  log.oinfo   :info_once,   "One time info"
  log.owarn   :warn_once,   "One time warning"
  log.owarn   :warn_once,   "One time warning"  # this line shall be skipped
  log.oinfo   :info_once,   "One time info"     # this line shall be skipped too
  # from the output, even this is looped 5 times, only 4 messages shall be printed out
end

log.info "Shall turned off all except tag :whatever"
log.off_all_except(:whatever,:global)
log.tdebug :another_global, "I've been turned off"  # this line shall not show in the log output
log.terror :whatever, "I will survive!"             # this line will show up because it is being exampted
log.tinfo :global, "Got turned off"                 # this line will show up because it is being exampted 

log.remove_from_exception(:global)
log.twarn :global, "Since :global is removed from exception, will it print out?"  # this line will not show up because it has removed from examption and shall be off

log.on_all_except(:global)
log.tdebug :another_global, "Now it is my turn to be here"          # this line will show up because all is on
log.terror :whatever, "Yeah me too!"                                # this line will show up because all is on
log.debug "I'm inherited from key :global so I'm also not visible"  # due to on_all_except(:global) this line shall not be printed
log.tinfo :global, "Gosh! I've been turned off by default"          # due to on_all_except(:global) this line shall not be printed
log.twarn :local, "I'm free!"                                       # this line will show up because all is on

