Facter.add('choco_sources') do
  confine :kernel => 'windows'
  setcode do
    chocopath = Facter.value(:choco_install_path)

    new_choco_min_version = '0.9.9'
    chocoversion = Facter.value(:choco_version)
    new_choco = Gem::Version.new(chocoversion) >= Gem::Version.new(new_choco_min_version)

    sources_hash = {}

    if chocoversion
      powershell = 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe'

      command = case new_choco
        when true then "#{chocopath}\\bin\\choco.exe source list -r"
        when false then "#{chocopath}\\bin\\choco.exe sources list"
      end

      output = Facter::Core::Execution.exec(%Q{#{powershell} -command "#{command}"})
      output_lines_array = output.split("\n") # put output lines in an array

      if new_choco
        # New choco output processing
        output_lines_array.each do |source|
          source_match = source.match(/(^.*?)(?: \[(.*)\])? - (.*)$/)
          sources_hash[source_match[1]] = {
            'status'   => source_match[2] == 'Disabled' ? 'Disabled' : 'Enabled',
            'location' => source_match[3],
          }
        end
      else
        # Old choco output processing
        if output_lines_array.count >= 4
          sources_lines_indexes = (3..-1)
          sources_lines_array = output_lines_array[sources_lines_indexes]
          sources_lines_array.each do |source|
            source_match = source.match(/(^.*?[^ ]) +(.*?) *$/)
            if source_match[1]
              sources_hash[source_match[1]] = {
                # Set 'status' to 'Enabled' as we have no way to check if a source is disabled
                # with the choco command line.
                'status'   => 'Enabled',
                'location' => source_match[2],
              }
            end
          end
        end
      end
    end
    sources_hash
  end
end
