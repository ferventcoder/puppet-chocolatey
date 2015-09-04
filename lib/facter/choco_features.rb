Facter.add('choco_features') do
  confine :kernel => 'windows'
  setcode do
    chocopath = Facter.value(:choco_install_path)

    new_choco_min_version = '0.9.9'
    chocoversion = Facter.value(:choco_version)
    new_choco = Gem::Version.new(chocoversion) >= Gem::Version.new(new_choco_min_version)

    features_hash = {}

    if chocoversion
      if new_choco
        powershell = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'
        command = "#{chocopath}\\bin\\choco.exe feature list -r"
        output = Facter::Core::Execution.exec(%Q{#{powershell} -command "#{command}"})
        output_lines_array = output.empty? ? [] : output.split("\n")
        output_lines_array.each do |feature|
          feature_split = feature.match(/(^.*) - \[(.*)\]/)
          features_hash[feature_split[1]] = {
            'status' => feature_split[2],
          }
        end
      end
    end
    features_hash
  end
end
