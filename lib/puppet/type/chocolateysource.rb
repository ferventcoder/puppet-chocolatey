require 'puppet/type'
require 'pathname'

Puppet::Type.newtype(:chocolateysource) do

  @doc = <<-'EOT'
    TODO

  EOT

  def initialize(*args)
    super

    # if location is unset, use the title
    if self[:location].nil? then
      self[:location] = self[:name]
    end
  end

  ensurable do
    newvalue(:exists?)  { provider.exists? }
    newvalue(:present)  { provider.create }
    newvalue(:disabled) { provider.disable }
    newvalue(:absent)   { provider.destroy }
    #defaultto { :present }
    defaultto :present

    def retrieve
      provider.properties[:ensure]
    end

  end

  newparam(:name) do
    desc "The name of the source. Used for uniqueness. Will set
      the location to this value if location is unset."

    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty name must be specified."
      end
    end

    isnamevar

    munge do |value|
      value.downcase
    end

    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newproperty(:location) do
    desc "The location of the source repository. Can be a url pointing to
      an OData feed (like chocolatey/chocolatey_server), a CIFS (UNC) share,
      or a local folder.
      The default is the name of the resource"

    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty location must be specified."
      end
    end

    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newproperty(:user) do
    desc "Optional user name for authenticated feeds.
      Requires at least Chocolatey v0.9.9.0.
      Defaults to `nil`."

    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty user must be specified."
      end
    end

    # get the chocolatey version and provide
    # warnings when ignoring
    # username / password - choco < 0.9.9.0
  end

  newparam(:password) do
    desc "Optional user password for authenticated feeds.
      Not ensurable. Value is not able to be checked
      with current value. If you need to update the password,
      update another setting as well.
      Requires at least Chocolatey v0.9.9.0.
      Defaults to `nil`."

    validate do |value|
      if value.nil? or value.empty?
        raise ArgumentError, "A non-empty password must be specified."
      end
    end

    # get the chocolatey version and provide
    # warnings when ignoring
    # username / password - choco < 0.9.9.0
  end

  newproperty(:priority) do
    desc "Optional priority for explicit feed order when
      searching for packages across multiple feeds.
      The lower the number the higher the priority.
      Sources with a 0 priority are considered no priority
      and are added after other sources with a priority
      number.
      Requires at least Chocolatey v0.9.9.9.
      Defaults to `nil` or 0."

    validate do |value|
      if value.nil?
        raise ArgumentError, "A non-empty priority must be specified."
      end
      raise ArgumentError, "An integer is necessary for priority. Specify 0 or remove for no priority." unless resource.is_numeric?(value)
    end

    # priority - choco < 0.9.9.9
    # let's validate the choco version and provide a
    # warning that this will be ignored.



    # if the version of choco is 0.9.9.9,
    # then default it to 0.
    # Otherwise don't specify a default.
    defaultto(0)
  end

  validate do
    if (!self[:user].nil? && self[:password].nil?) || (self[:user].nil? && !self[:password].nil?)
      raise ArgumentError, "If specifying user name/password, must specify both values."
    end

    if provider.respond_to?(:validate)
      provider.validate
    end
  end

  autorequire(:exec) do
    ['install_chocolatey_official']
  end

  def munge_boolean(value)
    case value
      when true, "true", :true
        :true
      when false, "false", :false
        :false
      else
        fail("munge_boolean only takes booleans")
    end
  end

  def is_numeric?(value)
    # this is what stdlib does. Not sure if we want to emulate or not.
    #numeric = %r{^-?(?:(?:[1-9]\d*)|0)$}
    #if value.is_a? Integer or (value.is_a? String and value.match numeric)
    Float(value) != nil rescue false
  end
end
