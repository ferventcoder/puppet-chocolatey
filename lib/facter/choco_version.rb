Facter.add('choco_version') do
  confine :kernel => 'windows'
  setcode do
    version = nil
    chocopath = Facter.value(:choco_install_path)
    if File.exist? chocopath
      powershell = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'

      # Using 'choco.exe' command insteed of 'choco.exe --version' as the last
      # is not supported on versions below 0.9.9
      #
      # Example output
      #   0.9.8.31: 'Please run chocolatey /? or chocolatey help - chocolatey v0.9.8.31'
      #   0.9.9.8:  'Chocolatey v0.9.9.8'
      #
      # The needed version will be found with following regex pattern:
      #   /[c|C]hocolatey v(.*)$/
      #
      command = "#{chocopath}\\bin\\choco.exe"
      version_string = Facter::Core::Execution.exec(%Q{#{powershell} -command "#{command}"})
      version = version_string.match(/[c|C]hocolatey v(.*)$/)[1]
    end
    version
  end
end
