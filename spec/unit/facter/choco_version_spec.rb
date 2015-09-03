require 'spec_helper'

describe 'choco_version fact', :type => :fact do

  before :each do
    Facter.fact(:kernel).stubs(:value).returns('windows')
    Facter.fact(:choco_install_path).stubs(:value).returns('C:\ProgramData\chocolatey')
  end

  let(:powershell) { 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe' }
  let(:chocopath) { Facter.value(:choco_install_path) }
  let(:command) { "#{chocopath}\\bin\\choco.exe" }
  let(:exec) { %Q{#{powershell} -command "#{command}"} }

  context 'when chocolatey is installed' do
    before :each do
      ::File.stubs(:exist?).
        with(chocopath).
        returns(true)
    end

    context 'with version < 0.9.9' do
      before :each do
        Facter::Core::Execution.stubs(:exec).
          with(exec).
          returns("Please run chocolatey /? or chocolatey help - chocolatey v0.9.8.31")
      end

      it 'should return version' do
        Facter.fact(:choco_version).value.should == '0.9.8.31'
      end
    end

    context 'with version >= 0.9.9' do
      before :each do
        Facter::Core::Execution.stubs(:exec).
          with(exec).
          returns("Chocolatey v0.9.9.8")
      end

      it 'should return version' do
        Facter.fact(:choco_version).value.should == '0.9.9.8'
      end
    end
  end

  context 'when chocolatey is not installed' do
    before :each do
      ::File.stubs(:exist?).
        with(chocopath).
        returns(false)
    end

    it 'should return nil' do
      Facter.fact(:choco_version).value.should be_nil
    end
  end

  after :each do
    Facter.clear
    Facter.clear_messages
  end

end