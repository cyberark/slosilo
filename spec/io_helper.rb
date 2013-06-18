class IO
  def grab &block
    @grabbed_output = ""
    class << self
      def write arg
        @grabbed_output += arg
      end
    end

    begin
      yield
    ensure
      singleton_class.send :remove_method, :write
    end

    @grabbed_output
  end
end
