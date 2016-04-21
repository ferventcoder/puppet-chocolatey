require 'pathname'
require Pathname.new(__FILE__).dirname + 'chocolatey_version'
require Pathname.new(__FILE__).dirname + 'chocolatey_install'

module PuppetX
  module Chocolatey
    module ChocolateyCommon

      def file_exists?(path)
        File.exist?(path)
      end
      module_function :file_exists?

      def chocolatey_command
        if Puppet::Util::Platform.windows?
          chocoInstallPath = PuppetX::Chocolatey::ChocolateyInstall.install_path
          #default_location = $::choco_installpath || ENV['ALLUSERSPROFILE'] + '\chocolatey'
          chocopath = ('C:\ProgramData\chocolatey' if file_exists?('C:\ProgramData\chocolatey\bin\choco.exe')) ||
              (chocoInstallPath if chocoInstallPath && file_exists?("#{chocoInstallPath}\\bin\\choco.exe")) ||
              (ENV['ChocolateyInstall'] if ENV['ChocolateyInstall'] && file_exists?("#{ENV['ChocolateyInstall']}\\bin\\choco.exe")) ||
              ('C:\Chocolatey' if file_exists?('C:\Chocolatey\bin\choco.exe')) ||
              "#{ENV['ALLUSERSPROFILE']}\\chocolatey"

          chocopath += '\bin\choco.exe'
        else
          chocopath = 'choco.exe'
        end

        chocopath
      end
      module_function :chocolatey_command

      def set_env_chocolateyinstall
        ENV['ChocolateyInstall'] = PuppetX::Chocolatey::ChocolateyInstall.install_path
      end
      module_function :set_env_chocolateyinstall

      # this ultimately determines if we are on the C# version of choco
      # so commands can be adjusted accordingly
      def choco_exe?
        @compiled_choco ||= Gem::Version.new(choco_version) >= Gem::Version.new('0.9.9.0')
      end
      module_function :choco_exe?

      def choco_version
        @chocoversion ||= self.strip_beta_from_version(PuppetX::Chocolatey::ChocolateyVersion.version)
      end
      module_function :choco_version

      def self.strip_beta_from_version(value)
        value.split(/-/)[0]
      end

      def compiled_choco=(value)
        @compiled_choco = value
      end

      def choco_config_file
        chocoInstallPath = PuppetX::Chocolatey::ChocolateyInstall.install_path
        choco_config = "#{chocoInstallPath}\\config\\chocolatey.config"

        return choco_config if file_exists?(choco_config)

        return nil
      end
      module_function :choco_config_file

      #def choco_ver_cmd
      #  args = []
      #  args << '-v'
      #
      #  #Puppet::Util::Execution.execute()
      #  #Puppet::Execution::exec_util()
      #  [chocolatey_command, *args]
      #end
      #module_function :choco_ver_cmd

    end
  end
end
