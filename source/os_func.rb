module OsFunctions
  def self.is_windows?
    RUBY_PLATFORM.downcase.include?("mswin") || RUBY_PLATFORM.downcase.include?("mingw")
  end

  def self.is_linux?
    RUBY_PLATFORM.downcase.include?("linux")
  end
end