module STAF
  class STAFResult
    def initialize(rc, result)
      @rc = rc;
      @result = result;
    end

    attr_reader :rc, :result;
  end
end
