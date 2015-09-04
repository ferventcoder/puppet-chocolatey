require 'spec_helper'
require 'rspec/its'

describe 'choco_features fact', :type => :fact do
  subject(:fact) { Facter.fact(:choco_features) }

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

    context 'with version > 0.9.9' do
      before :each do
        Facter.fact(:choco_version).stubs(:value).returns('0.9.9.8')
      end

      context 'with all features enabled' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
checksumFiles - [Enabled]
autoUninstaller - [Enabled]
allowGlobalConfirmation - [Enabled]
failOnAutoUninstaller - [Enabled]
EOR
  )
        end

        it 'should return the correct features status hash' do
          Facter.fact(:choco_features).value.should include(
            'checksumFiles'           => {'status' => 'Enabled'},
            'autoUninstaller'         => {'status' => 'Enabled'},
            'allowGlobalConfirmation' => {'status' => 'Enabled'},
            'failOnAutoUninstaller'   => {'status' => 'Enabled'},
          )
        end
      end

      context 'with all features disabled' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
checksumFiles - [Disabled]
autoUninstaller - [Disabled]
allowGlobalConfirmation - [Disabled]
failOnAutoUninstaller - [Disabled]
EOR
  )
        end

        it 'should return the correct features status hash' do
          Facter.fact(:choco_features).value.should include(
            'checksumFiles'           => {'status' => 'Disabled'},
            'autoUninstaller'         => {'status' => 'Disabled'},
            'allowGlobalConfirmation' => {'status' => 'Disabled'},
            'failOnAutoUninstaller'   => {'status' => 'Disabled'},
          )
        end
      end

    end

    context 'with version <= 0.9.9' do
      before :each do
        Facter.fact(:choco_version).stubs(:value).returns('0.9.8.31')
      end
      it 'should return an empty hash' do
        Facter.fact(:choco_features).value.should be_eql({})
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
      Facter.fact(:choco_features).value.should be_eql({})
    end
  end

  after :each do
    Facter.clear
    Facter.clear_messages
  end

end