

require "tlogger"
include Tlogger

mlog = LoggerGroup.new
# create logger goes to STDOUT
lout = mlog.create_logger(:stdout, STDOUT)
# create logger using default parameter, to STDOUT too
# lout = mlog.create_logger(:stdout2)
# create logger to a log file test.log
lfile = mlog.create_logger(:file,"test.log", 10, 1024000)
# create logger to memory buffer
buf = StringIO.new
lbuf = mlog.create_logger(:io,buf)


mlog.with_tag(:block) do |log|
  # following 4 lines shall all be printed in all given 3 loggers
  log.debug "inside block"
  log.error "Wow error!"
  log.info  "Still inside block"
  log.warn  "Warning!"

  # following 2 lines shall only got 1 line printed in all 3 loggers
  log.odebug :once, "this should print out once!"
  log.odebug :once, "this should print out once!"
end


# following two lines shall be printed on STDOUT only
lout.tdebug :test, "test output"
lout.debug "again"

ioLog = mlog.detach_logger(:io)

# this line shall not be printed to memory buffer but shall be in other 2
mlog.debug "Last line"

ioLog.info "This only inside memory buffer"

buf.rewind
dat = buf.read
puts "**** Content of memory buffer ****"
dat.each_line do |l|
  puts l.strip
end
puts "**** End of content of memory buffer ****"

mlog.close

# since this log already detach, application should close it when finished using it
ioLog.close

