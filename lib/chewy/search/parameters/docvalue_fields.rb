require 'chewy/search/parameters/value'

module Chewy
  module Search
    class Parameters
      class DocvalueFields < Value
        include StringArrayStorage
      end
    end
  end
end
