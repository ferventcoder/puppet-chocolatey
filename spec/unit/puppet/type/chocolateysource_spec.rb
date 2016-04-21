require 'spec_helper'
require 'puppet/type/chocolateysource'

describe Puppet::Type.type(:chocolateysource) do
  let(:resource) { Puppet::Type.type(:chocolateysource).new(:name => "source") }
  let(:provider) { Puppet::Provider.new(resource) }
  let(:catalog) { Puppet::Resource::Catalog.new }

  before :each do
    resource.provider = provider
  end

  it "should be an instance of Puppet::Type::Chocolateysource" do
    resource.must be_an_instance_of Puppet::Type::Chocolateysource
  end

  it "parameter :name should be the name var" do
    resource.parameters[:name].isnamevar?.should be_truthy
  end

  #string values
  ['name','location','user','password'].each do |param|
    context "parameter :#{param}" do
      let (:param_symbol) { param.to_sym }

      it "should not allow nil" do
        expect {
          resource[param_symbol] = nil
        }.to raise_error(Puppet::Error, /Got nil value for #{param}/)
      end

      it "should not allow empty" do
        expect {
          resource[param_symbol] = ''
        }.to raise_error(Puppet::ResourceError, /A non-empty #{param} must/)
      end

      it "should accept any string value" do
        resource[param_symbol] = 'value'
        resource[param_symbol] = "c:/thisstring-location/value/somefile.txt"
        resource[param_symbol] = "c:\\thisstring-location\\value\\somefile.txt"
      end
    end
  end

  #numeric values
  ['priority'].each do |param|
    context "parameter :#{param}" do
      let (:param_symbol) { param.to_sym }

      it "should accept any numeric value" do
        resource[param_symbol] = 0
        resource[param_symbol] = 10
      end

      it "should accept any string that represents a numeric value" do
        resource[param_symbol] = '1'
        resource[param_symbol] = '0'
      end

      it "should not accept other string values" do
        expect {
          resource[param_symbol] = 'value'
        }.to raise_error(Puppet::ResourceError, /An integer is necessary for priority/)
      end

      it "should not accept symbol values" do
        expect {
          resource[param_symbol] = :whenever
        }.to raise_error(Puppet::ResourceError, /An integer is necessary for priority/)
      end
    end
  end

  context "param :ensure" do
    it "should accept 'present'" do
      resource[:ensure] = 'present'
    end

    it "should accept present" do
      resource[:ensure] = :present
    end

    it "should accept :disabled" do
      resource[:ensure] = :disabled
    end

    it "should accept absent" do
      resource[:ensure] = :absent
    end

    it "should reject any other value" do
      expect {
        resource[:ensure] = :whenever
      }.to raise_error(Puppet::ResourceError, /Invalid value :whenever. Valid values are/)
    end
  end

  #context "param :enable" do
  #  it "should default to true" do
  #    resource[:enable].must == :true
  #  end
  #end

  ##boolean values
  #['enable'].each do |param|
  #  context "param :#{param}" do
  #    let (:param_symbol) { param.to_sym }
  #
  #    it "should accept true" do
  #      resource[param_symbol] = true
  #    end
  #
  #    it "should accept false" do
  #      resource[param_symbol] = false
  #    end
  #
  #    it "should accept :true" do
  #      resource[param_symbol] = :true
  #    end
  #
  #    it "should accept :false" do
  #      resource[param_symbol] = :false
  #    end
  #
  #    it "should accept 'true'" do
  #      resource[param_symbol] = 'true'
  #    end
  #
  #    it "should accept 'false'" do
  #      resource[param_symbol] = 'false'
  #    end
  #
  #    it "should reject non-boolean values" do
  #      expect {
  #        resource[param_symbol] = :whenever
  #      }.to raise_error(Puppet::ResourceError, /Invalid value :whenever. Valid values are/)
  #      expect {
  #        resource[param_symbol] = "yes"
  #      }.to raise_error(Puppet::ResourceError, /Invalid value "yes". Valid values are/)
  #    end
  #  end
  #end


  it "should autorequire Exec[install_chocolatey_official] when in the catalog" do
    exec = Puppet::Type.type(:exec).new(:name => "install_chocolatey_official", :path => "nope")
    catalog.add_resource resource
    catalog.add_resource exec

    reqs = resource.autorequire
    reqs.count.must == 1
    reqs[0].source.must == exec
    reqs[0].target.must == resource
  end


end
