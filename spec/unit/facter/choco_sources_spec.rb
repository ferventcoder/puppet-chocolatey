require 'spec_helper'
require 'rspec/its'

describe 'choco_sources fact', :type => :fact do
  subject(:fact) { Facter.fact(:choco_sources) }

  before :each do
    Facter.fact(:kernel).stubs(:value).returns('windows')
    Facter.fact(:choco_install_path).stubs(:value).returns('C:\ProgramData\chocolatey')
  end

  let(:powershell) { 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe' }
  let(:chocopath) { Facter.value(:choco_install_path) }
  let(:command) { "#{chocopath}\\bin\\choco.exe feature list -r" }
  let(:exec) { %Q{#{powershell} -command "#{command}"} }

  context 'when chocolatey is installed' do
    before :each do
      File.stubs(:exist?).
        with(chocopath).
        returns(true)
    end

    context 'with version >= 0.9.9' do
      before :each do
        Facter.fact(:choco_version).stubs(:value).returns('0.9.9.8')
      end

      context 'with all sources enabled' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
mysource1 - http://mysource1/api/v2
mysource2 - http://mysource2/api/v2
mysource3 - http://mysource3/api/v2
EOR
  )
        end

        it 'should return the correct sources hash' do
          Facter.fact(:choco_sources).value.should include(
            'mysource1' => {
              'location' => 'http://mysource1/api/v2',
              'status'   => 'Enabled'
            },
            'mysource2' => {
              'location' => 'http://mysource2/api/v2',
              'status'   => 'Enabled'
            },
            'mysource3' => {
              'location' => 'http://mysource3/api/v2',
              'status'   => 'Enabled'
            },
          )
        end
      end

      context 'with all sources disabled' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
mysource1 [Disabled] - http://mysource1/api/v2
mysource2 [Disabled] - http://mysource2/api/v2
mysource3 [Disabled] - http://mysource3/api/v2
EOR
  )
        end

        it 'should return the correct sources hash' do
          Facter.fact(:choco_sources).value.should include(
            'mysource1' => {
              'location' => 'http://mysource1/api/v2',
              'status'   => 'Disabled'
            },
            'mysource2' => {
              'location' => 'http://mysource2/api/v2',
              'status'   => 'Disabled'
            },
            'mysource3' => {
              'location' => 'http://mysource3/api/v2',
              'status'   => 'Disabled'
            },
          )
        end
      end

      context 'without sources' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
EOR
  )
        end

        it 'should return an empty hash' do
          Facter.fact(:choco_sources).value.should be_eql({})
        end
      end

    end

    context 'with version < 0.9.9' do
      before :each do
        Facter.fact(:choco_version).stubs(:value).returns('0.9.8.31')
      end

      context 'with all sources enabled (we only can see enabled sources)' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR

ID                        URI
--                        ---
mysource1                 http://mysource1/api/v2
mysource2                 http://mysource2/api/v2
mysource3                 http://mysource3/api/v2

EOR
  )
        end

        it 'should return the correct sources hash' do
          Facter.fact(:choco_sources).value.should include(
            'mysource1' => {
              'location' => 'http://mysource1/api/v2',
              'status'   => 'Enabled'
            },
            'mysource2' => {
              'location' => 'http://mysource2/api/v2',
              'status'   => 'Enabled'
            },
            'mysource3' => {
              'location' => 'http://mysource3/api/v2',
              'status'   => 'Enabled'
            },
          )
        end
      end

      context 'without any sources' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
EOR
)
        end

        it 'should return an empty hash' do
          Facter.fact(:choco_sources).value.should be_eql({})
        end
      end

    end
  end

  context 'when chocolatey is not installed' do
    before :each do
      File.stubs(:exist?).
        with(chocopath).
        returns(false)
    end
    it 'should return an empty hash' do
      Facter.fact(:choco_sources).value.should be_eql({})
    end
  end

  after :each do
    Facter.clear
    Facter.clear_messages
  end

end