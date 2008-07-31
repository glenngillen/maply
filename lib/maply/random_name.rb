module Maply
  module RandomName
    private
    def short_code(first_lowercase = false)
      characters = []
      ("a".."z").each do |l|
        characters << l
      end
      ("A".."Z").each do |l|
        characters << l
      end
      ("0".."9").each do |l|
        characters << l
      end

      uid = []
      5.times do |i|
        if i == 0 && first_lowercase
          uid << characters[26*rand]
        else
          uid << characters[characters.size*rand]
        end
      end      

      return uid.join
    end
  end
end