Facter.add('choco_apikeys') do
  confine :kernel => 'windows'
  setcode do
    chocopath = Facter.value(:choco_install_path)

    new_choco_min_version = '0.9.9'
    chocoversion = Facter.value(:choco_version)
    new_choco = Gem::Version.new(chocoversion) >= Gem::Version.new(new_choco_min_version)

    apikeys_hash = {}

    if chocoversion
      if new_choco
        powershell = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'
        command = "#{chocopath}\\bin\\choco.exe apikey -r"
        output = Facter::Core::Execution.exec(%Q{#{powershell} -command "#{command}"})
        output_lines_array = output.empty? ? [] : output.split("\n")
        output_lines_array.each do |apikey|
          apikey_split = apikey.match(/(^.*)\|(.*)/)
          apikeys_hash[apikey_split[1]] = {
            'apikey' => apikey_split[2],
          }
        end
      end
    end
    apikeys_hash
  end
end
