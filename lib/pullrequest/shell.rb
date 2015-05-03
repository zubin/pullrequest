module Pullrequest
  module Shell
    def execute(command)
      Kernel.exec command
    end
  end
end
