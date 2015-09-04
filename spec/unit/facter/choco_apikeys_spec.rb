require 'spec_helper'
require 'rspec/its'

describe 'choco_apikeys fact', :type => :fact do
  subject(:fact) { Facter.fact(:choco_apikeys) }

  before :each do
    Facter.fact(:kernel).stubs(:value).returns('windows')
    Facter.fact(:choco_install_path).stubs(:value).returns('C:\ProgramData\chocolatey')
  end

  let(:powershell) { 'C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe' }
  let(:chocopath) { Facter.value(:choco_install_path) }
  let(:command) { "#{chocopath}\\bin\\choco.exe apikey list -r" }
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

      context 'with apikeys' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
http://mysource1/api/v2|mysupersecretapikey1
http://mysource2/api/v2|mysupersecretapikey2
http://mysource3/api/v2|mysupersecretapikey3
EOR
  )
        end

        it 'should return the correct apikeys hash' do
          Facter.fact(:choco_apikeys).value.should include(
            'http://mysource1/api/v2' => {'apikey' => 'mysupersecretapikey1'},
            'http://mysource2/api/v2' => {'apikey' => 'mysupersecretapikey2'},
            'http://mysource3/api/v2' => {'apikey' => 'mysupersecretapikey3'},
          )
        end
      end

      context 'without any apikeys' do
        before :each do
          Facter::Core::Execution.stubs(:exec).
            returns(<<-EOR
EOR
  )
        end

        it 'should return an empty hash' do
          Facter.fact(:choco_apikeys).value.should be_eql({})
        end
      end

    end

    context 'with version <= 0.9.9' do
      before :each do
        Facter.fact(:choco_version).stubs(:value).returns('0.9.8.31')
      end
      it 'should return an empty hash' do
        Facter.fact(:choco_apikeys).value.should be_eql({})
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
      Facter.fact(:choco_apikeys).value.should be_eql({})
    end
  end

  after :each do
    Facter.clear
    Facter.clear_messages
  end

end