require 'cumo/narray'
require 'numo/narray'

module Cumo
  class Int32
    def bincount(opt={})
      ::Cumo::Int32[*(::Numo::Int32[*(self)].bincount(opt))]
    end
  end
end

