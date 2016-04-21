$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "../log-merge", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))


require 'log-merge'
require_relative 'lib/color_picker'
require_relative 'lib/helpers'


# filename = '/Users/sodonnell/Desktop/merge_logs/zookeeper-cmf-zookeeper1-SERVER-dc5b01.bell.corp.bce.ca.txt'
# filename = '/Users/sodonnell/Desktop/merge_logs/1000_lines.txt'
$logfile = nil
$logfile_index_filename = nil
$logfile_index = nil
$alias_color_picker = ColorPicker.new


opts = OptionParser.new do |opts|
  opts.on("-f", "--file FILE", "Path to the log file to serve") do |f|
    unless File.exist?(f)
      puts "Requested file #{f} does not exist"
      exit(1)
    end
    $logfile = f
  end
  opts.on("-i", "--index FILE", "Index associated with the log file to serve") do |f|
    unless File.exist?(f)
      puts "Requested index #{f} does not exist"
      exit(1)
    end
    begin
      $logfile_index = LogMerge::Index.new
      $logfile_index.load(f)
    rescue =>  e
      puts "Failed to load the index - are you sure it is a valid index?"
      puts e
      exit(1)
    end
    $logfile_index_filename
  end
end

# This needs to run before Sinatra is required, otherwise Sinatra
# tries to parse the command line options and it does not like them
opts.parse(ARGV)
# This will warn about constant initialised, but unless it is cleared
# sinatra will error with bad command line options. This also means
# that none of the Sinatra options will work if they are passed now
ARGV = []

require 'sinatra'

helpers LogServer::Helpers

# If no index was passed in, check if there is one named the same as the logfile
# ending in .index - if so load it.
if $logfile_index == nil
  index = "#{$logfile}.index"
  if File.exists?(index)
    begin
      $logfile_index = LogMerge::Index.new
      $logfile_index.load(index)
      $logfile_index_filename = index
    rescue =>  e
      warn "Attempted to load index #{index} which failed"
      puts e
    end
  end
end


def open_resources_at_position(f, index, pos=0)
  @fh = File.open(f, 'r')
  @fh.seek(pos, IO::SEEK_SET)
  @lr = LogMerge::LogReader.new(@fh)
  @lr.index = index
end

def close_resources
  @fh.close
  @lr = nil
end



get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

# TODO - this is slow - 300MB log file, searching to the end takes 45seconds. Need to use
#         an index to select a starting position.
post '/gotodate' do
  begin
    date_string = params['datetime']
    open_resources_at_position($logfile, $logfile_index, 0)
    # TODO - exception handling!?!
    dtm = DateTime.strptime(date_string, "%Y-%m-%d %H:%M:%S")
    @lr.skip_to_time(dtm)
    new_position = @lr.io_position

    # check to see if the current line is nil - if it is, then the requested date
    # is after the last date in the file
    past_eof = @lr.next.nil? ? true : false
    erb :gotodate, :locals => { :new_position => new_position, :date_not_present => past_eof}
  ensure
    close_resources
  end
end


get '/loglines' do
  begin
    log_position = params['position'].to_i || 0
    eof = false
    open_resources_at_position($logfile, $logfile_index, log_position)

    str = ''
    lines = []
    1.upto(350) do |i|
      line = @lr.next
      if line
        lines.push line
      else
        eof = true
        break
      end
    end
    str << erb(:logline, :locals => { :lines => lines })
    new_position = @lr.io_position
    
    erb :more, :locals => { :log_data => str, :log_position => new_position.to_s, :no_more_messages => eof }
  ensure
    close_resources
  end
end
