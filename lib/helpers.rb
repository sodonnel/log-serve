module LogServer
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
      $alias_color_picker.get_color(str)
    end
    
  end
end
