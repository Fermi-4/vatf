module STAF
  class STAFException < Exception
    def initialize(rc, text, name='STAFException')
      super(text)
      @text = text
      @rc = rc
      @name = name
    end

    attr_reader :rc, :name

    def message
      "Error code: #{@rc}\n" +
      "Name      : #{@name}\n" +
      "Error text: #{@text}\n"
    end

    def to_s
      message
    end
  end

  class STAFInvalidObjectException < STAFException
    def initialize(rc, text)
      super(rc, text, "STAFInvalidObjectException");
    end
  end

  class STAFInvalidParmException < STAFException
    def initialize(rc, text)
      super(rc, text, "STAFInvalidParmException");
    end
  end

  class STAFBaseOSErrorException < STAFException
    def initialize(rc, text)
      super(rc, text, "STAFBaseOSErrorException");
    end
  end
end

