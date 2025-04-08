##
# Classes and methods for working with radiocarbon date metadata.
#
# Mostly adapted from R: https://github.com/joeroe/c14
# 
module C14Metadata

  ##
  # Radiocarbon dates are conventionally labelled with compound identifiers
  # consisting of a lab code prefix (e.g. 'B' for Bern) and a unique lab number
  # (e.g. 'B-1234'). The two parts are usually joined with a space or a hyphen,
  # the lab code usually consists of 1-8 letters, and the lab number is usually
  # numeric – but deviations from all of these patterns are common!
  #
  class C14Identifier
    attr_reader :identifier

    StandardPattern = /([[[:alpha:]]\(\)]{1,8})\-([0-9]+)$/
    UndelimPattern = /([[[:alpha:]]\(\)]{1,8})([0-9]+)$/
    DelimPattern = /[ \-–_#\.\+]+/

    def initialize(identifier)
      @identifier = identifier
    end

    def to_s
      @identifier
    end

    def parsable?
      parse.length == 2
      # TODO: check that the two elements look reasonable?
    end

    def lab_code
      return nil unless parsable?
      parse[0]
    end

    def lab_number
      return nil unless parsable?
      parse[1]
    end

    def standard?
      StandardPattern.match?(identifier)
    end

    def standardize
      unless parsable?
        raise "Identifier is not parsable"
      end
      parse.join('-')
    end

    def standardize!
      @identifier = standardize
    end

    protected

    def parse
      # Safest to split by a delimiter
      if DelimPattern.match?(identifier)
        identifier.split(DelimPattern)
      # Or as a last resort
      else
        identifier.match(UndelimPattern).captures
      end
    end

  end

end
