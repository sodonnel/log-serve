class ColorPicker

  # TODO - this will fail after the 15th color has been used
  
  def initialize
    @colors = %w(black blue blueViolet brown cadetBlue crimson darkBlue darkCyan darkGray DarkGreen DarkOliveGreen DarkOrange DarkRed DarkSlateBlue DarkSlateGray )
    @string_to_color_map = {}
  end

  # Given a string, pick the next available color and return it.
  # Passing the same string should always return the same color
  def get_color(str)
    @string_to_color_map[str] ? @string_to_color_map[str] : pick_color(str)
  end

  private

  def pick_color(str)
    c = @colors.shift
    @string_to_color_map[str] = c
  end  
  
end
