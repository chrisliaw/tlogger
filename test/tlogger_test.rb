require "test_helper"

class TloggerTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Tlogger::VERSION
  end

  def test_basic_tagging

    buf = StringIO.new
    log = Tlogger::Tlogger.new(buf)
    log.tag = "first"

    log.debug "This is debug message"
    log.error "This is error message"
    log.info  "This is info message"
    log.warn  "This is warning message"
    
    buf.rewind
    dat = buf.read

    etest(dat.lines[-4],:debug, :first, "This is debug message")
    etest(dat.lines[-3],:err, :first, "This is error message")
    etest(dat.lines[-2],:info,:first, "This is info message")
    etest(dat.lines[-1],:warn,:first, "This is warning message")

    log.close
  end

  def test_scoped_tag

    buf = StringIO.new
    log = Tlogger::Tlogger.new(buf)
    log.tag = "outside"
    
    log.with_tag(:second) do |l|
      l.debug "Inside"
    end

    log.debug "Outside"

    buf.rewind
    dat = buf.read

    etest(dat.lines[-2],:debug,:second, "Inside")
    etest(dat.lines[-1],:debug,:outside, "Outside")

    log.close
    
  end

  def test_t_interface

    buf = StringIO.new
    log = Tlogger::Tlogger.new(buf)

    log.tdebug :first,  "This is debug message"
    log.terror :second, "This is error message"
    log.tinfo  :third,  "This is info message"
    log.twarn  :forth,  "This is warning message"
    
    buf.rewind
    dat = buf.read

    etest(dat.lines[-4],:debug,:first, "This is debug message")
    etest(dat.lines[-3],:err, :second, "This is error message")
    etest(dat.lines[-2],:info, :third, "This is info message")
    etest(dat.lines[-1],:warn, :forth, "This is warning message")

    log.close

  end

  def test_tag_on_off

    buf = StringIO.new
    log = Tlogger::Tlogger.new(buf)

    log.off_tag(:third, :second)
    log.tdebug :first,  "This is debug message"
    log.terror :second, "This is error message"
    log.tinfo  :third,  "This is info message"
    log.twarn  :forth,  "This is warning message"

    log.on_tag(:second)
    log.terror :second, "This is reprint"
    
    buf.rewind
    dat = buf.read

    assert(dat.lines.length == 3)

    etest(dat.lines[-3], :debug, :first, "This is debug message")
    etest(dat.lines[-2],:warn, :forth, "This is warning message")
    etest(dat.lines[-1],:err, :second, "This is reprint")

    log.close
     
  end

  def test_show_once

    buf = StringIO.new
    log = Tlogger::Tlogger.new(buf)

    log.odebug :first,  "This is first message"
    log.oerror :first,  "This is first message"
    log.oinfo  :second, "This is second message"
    log.owarn  :second, "This is second message"
    log.owarn  :second_hand, "This is second message"

    buf.rewind
    dat = buf.read

    assert(dat.lines.length == 3)

    etest(dat.lines[-3],:debug, :first, "This is first message")
    etest(dat.lines[-2],:info, :second, "This is second message")
    etest(dat.lines[-1],:warn, :second_hand, "This is second message")

    log.close
     
  end

  def test_api_override
    
    buf = StringIO.new
    log = Tlogger::Tlogger.new(buf)

    log.debug :new_tag, "Debug on new tag"
    log.error :new_tag, "Error on new tag"
    log.info :new_tag, "Info on new tag"
    log.warn :new_tag, "Warn on new tag"

    buf.rewind
    dat = buf.read

    assert(dat.lines.length == 4)

    etest(dat.lines[-4],:debug, :new_tag, "Debug on new tag")
    etest(dat.lines[-3],:error, :new_tag, "Error on new tag")
    etest(dat.lines[-2],:info, :new_tag, "Info on new tag")
    etest(dat.lines[-1],:warn, :new_tag, "Warn on new tag")

    log.close

  end


  private
  def etest(ln, type, tag, msg)
    case type
    when :debug
      refute_nil(ln =~ /DEBUG/) 
    when :error, :err
      refute_nil(ln =~ /ERR/) 
    when :warn
      refute_nil(ln =~ /WARN/) 
    when :info
      refute_nil(ln =~ /INFO/) 
    end

    refute_nil(ln =~ /\[#{tag}\]/)
    refute_nil(ln =~ /#{msg}/)
  end

end
