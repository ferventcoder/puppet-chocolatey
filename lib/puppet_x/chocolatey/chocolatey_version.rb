require 'pathname'
require Pathname.new(__FILE__).dirname + 'chocolatey_install'

module PuppetX
  module Chocolatey
    class ChocolateyVersion

      def self.version
        version = nil
        choco_path = "#{PuppetX::Chocolatey::ChocolateyInstall.install_path}\\bin\\choco.exe"
        if Puppet::Util::Platform.windows? && File.exist?(choco_path)
          begin
            # call `choco -v`
            # - new choco will output a single value e.g. `0.9.9`
            # - old choco is going to return the default output e.g. `Please run chocolatey /?`
            old_choco_message = 'Please run chocolatey /? or chocolatey help - chocolatey v'
            version = Puppet::Util::Execution.execute("#{choco_path} -v").gsub(old_choco_message,'').strip
          rescue StandardError => e
            version = '0'
          end
        end

        version || '0'
      end
    end
  end
end
