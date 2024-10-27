module NeedsLods

  extend ActiveSupport::Concern

  included do # instance methods
    def lods
      self.class.lods.filter do |lod|
        self.needs_lods?(lod)
      end
    end

    def needs_lods?(lod)
      self.send(append_?(lod))
    end

    private
    
    def append_?(lod)
      (lod.to_s + "?").to_sym
    end
  end

  class_methods do
    attr_reader :lods

    def needs_lods?
      true
    end
  end

end
