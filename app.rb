$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "../log-merge", "lib"))
$:.unshift File.expand_path(File.dirname(__FILE__))


require 'log-merge'

# filename = '/Users/sodonnell/Desktop/merge_logs/zookeeper-cmf-zookeeper1-SERVER-dc5b01.bell.corp.bce.ca.txt'
# filename = '/Users/sodonnell/Desktop/merge_logs/1000_lines.txt'
$logfile = nil
$logfile_index_filename = nil
$logfile_index = nil


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


# These are helpers
# TODO - move to their own file
JS_ESCAPE_MAP = {
        '\\'    => '\\\\',
        '</'    => '<\/',
        "\r\n"  => '\n',
        "\n"    => '\n',
        "\r"    => '\n',
        '"'     => '\\"',
        "'"     => "\\'"
}

def escape_javascript(javascript)
  if javascript
    result = javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) {|match| JS_ESCAPE_MAP[match] }
  else
    ''
  end
end

def htmlify_newlines(str)
  str.gsub(/\n/, '<br />')
end

## End Helpers




get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

# TODO - this is slow - 300MB log file, searching to the end takes 45seconds. Need to use
#         an index to select a starting position.
post '/gotodate' do
  date_string = params['datetime']
  
  # TODO - exception handling!?!
  dtm = DateTime.strptime(date_string, "%Y-%m-%d %H:%M:%S")

  fh = File.open($logfile, 'r')
  lr = LogMerge::LogReader.new(fh)
  lr.skip_to_time(dtm)
  new_position = lr.io_position

  # check to see if the current line is nil - if it is, then the requested date
  # is after the last date in the file
  past_eof = lr.next.nil? ? true : false

  fh.close
  erb :gotodate, :locals => { :new_position => new_position, :date_not_present => past_eof}
end


get '/loglines' do

  log_position = params['position'].to_i || 0
  eof = false

  fh = File.open($logfile, 'r')
  fh.seek(log_position, IO::SEEK_SET)
  
  lr = LogMerge::LogReader.new(fh)
  
  str = ''
  lines = []
  1.upto(350) do |i|
    line = lr.next
    if line
      lines.push line
    else
      eof = true
      break
    end
  end
  str << erb(:logline, :locals => { :lines => lines })
  new_position = lr.io_position

  fh.close

  erb :more, :locals => { :log_data => str, :log_position => new_position.to_s, :no_more_messages => eof }

end
