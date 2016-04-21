require 'spec_helper'
require 'puppet_x/chocolatey/chocolatey_version'

describe 'Chocolatey Version' do

  context 'on Windows', :if => Puppet::Util::Platform.windows? do

    it "should return the value from running choco -v" do
      expected_value = '1.2.3'
      Puppet::Util::Execution.expects(:execute).returns(expected_value)

      PuppetX::Chocolatey::ChocolateyVersion.version.must == expected_value
    end

    it "should handle cleaning up spaces" do
      expected_value = '1.2.3'
      Puppet::Util::Execution.expects(:execute).returns(' ' + expected_value + ' ')

      PuppetX::Chocolatey::ChocolateyVersion.version.must == expected_value
    end

    it "should handle older versions of choco" do
      expected_value = '1.2.3'
      Puppet::Util::Execution.expects(:execute).returns('Please run chocolatey /? or chocolatey help - chocolatey v' + expected_value)

      PuppetX::Chocolatey::ChocolateyVersion.version.must == expected_value
    end
  end

  context 'on Linux', :if => Puppet.features.posix? do
    it "should return 0  on a non-windows system" do
      PuppetX::Chocolatey::ChocolateyVersion.version.must == "0"
    end
  end
end
