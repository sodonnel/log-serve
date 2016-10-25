module LogServe
  module Helpers

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
    
    def pick_alias_color(str)
      # See http://stackoverflow.com/a/21682946/88839 - using a MD5 hash here
      # as single character aliases would not work well with the BKR hash mentioned
      # in that stackoverflow post
      if str
        val = Digest::MD5.hexdigest(str).to_i(16) % 360
        "hsl(#{val},100%,30%)";
      else
        "black"
      end
    end
    
  end
end
