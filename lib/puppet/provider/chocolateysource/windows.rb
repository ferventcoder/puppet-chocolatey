require 'puppet/type'
require 'pathname'
require 'rexml/document'

Puppet::Type.type(:chocolateysource).provide(:windows) do
  confine :operatingsystem => :windows
  defaultfor :operatingsystem => :windows

  require Pathname.new(__FILE__).dirname + '../../../' + 'puppet_x/chocolatey/chocolatey_common'
  include PuppetX::Chocolatey::ChocolateyCommon

  commands :chocolatey => PuppetX::Chocolatey::ChocolateyCommon.chocolatey_command

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def properties
    if @property_hash.empty?
      @property_hash = query || { :ensure => ( :absent )}
      @property_hash[:ensure] = :absent if @property_hash.empty?
    end
    @property_hash.dup
  end

  def query
    self.class.sources.each do |source|
      return source.properties if @resource[:name][/\A\S*/].downcase == source.name.downcase
    end

    return {}
  end

  #def self.list
  #  args = []
  #  args << 'sources'
  #  if PuppetX::Chocolatey::ChocolateyCommon.choco_exe?
  #    args << 'list'
  #    args << '-r'
  #  end
  #
  #  [command(:chocolatey), *args]
  #end

  def self.get_sources
    sources = []
    PuppetX::Chocolatey::ChocolateyCommon.set_env_chocolateyinstall

    choco_config = PuppetX::Chocolatey::ChocolateyCommon.choco_config_file

    raise Puppet::ResourceError, "Config file not found for Chocolatey. Please make sure you have Chocolatey installed." if choco_config.nil?
    raise Puppet::ResourceError, "An install was detected, but was unable to locate config file at #{choco_config}." unless PuppetX::Chocolatey::ChocolateyCommon.file_exists?(choco_config)
    #todo throw an error if the config is null

    Puppet.debug("Gathering sources from '#{choco_config}'.")
    config = REXML::Document.new File.new(choco_config, "r")
    sources = config.elements.to_a( "//source" )

    #REXML::XPath.each(config, "//source") do |source|
    #  sources << source
    #end

    #begin
    #  sources = Puppet::Util::Execution.execute(self.list).strip().split("\n")
    #rescue Puppet::ExecutionFailure
    #  # add message about unable to execute
    #end

    #sources.reject { |s| s.empty? }
  end

  def self.get_source(element)
    source = {}

    return source if element.nil?

    source[:name] = element.attributes['id'].downcase if element.attributes['id']
    source[:location] = element.attributes['value'].downcase if element.attributes['value']

    disabled = false
    disabled = element.attributes['disabled'].downcase == 'true' if element.attributes['disabled']
    source[:ensure] = :present
    source[:ensure] = :disabled if disabled

    source[:priority] = 0
    source[:priority] = element.attributes['priority'].downcase if element.attributes['priority']

    source[:user] = element.attributes['user'].downcase if element.attributes['user']

    #source_name = ''
    #/^(?<source_name>\S+)\s*/ =~ item
    #source[:name] = source_name.downcase
    #
    #location = ''
    #/-\s*(?<location>\S+)\s+?/ =~ item
    #source[:location] = location.downcase
    #
    #source[:ensure] = :present
    #
    #disabled = item =~ /\[Disabled\]/i
    #source[:ensure] = :disabled if disabled
    #
    #authenticated = item =~ /\(Authenticated\)/i
    #source[:authenticated] = :true if authenticated
    #
    #priority = 0
    #item =~ /\|\s*Priority\s*(?<priority>\d+)/i
    #source[:priority] = priority

    Puppet.debug("Loaded source '#{source.inspect}'.")

    source
  end

  def self.sources
    @sources ||=  get_sources.collect do |item|
      source = get_source(item)
      new(source)
    end
  end

  def self.refresh_sources
    @sources = nil
    self.sources
  end

  def self.instances
    sources
  end

  def self.prefetch(resources)
    instances.each do |provider|
      if (resource = resources[provider.name])
        resource.provider = provider
      end
    end
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def disable
    @property_flush[:ensure] = :disabled
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def validate
    #todo more validation based on choco version maybe here
    #todo if user name is passed, we should validate user password is also set
  end

  mk_resource_methods

  def flush
    args = []
    args << 'sources'

    command = 'add'
    command = 'remove' if @property_flush[:ensure] == :absent

    args << command
    args << '--name' << resource[:name]

    if @property_flush[:ensure] != :absent
      args << '--source' << resource[:location]

      if resource[:user]
        args << '--user' << resource[:user]
        args << '--password' << resource[:password]
      end

      if Gem::Version.new(PuppetX::Chocolatey::ChocolateyCommon.choco_version) >= Gem::Version.new('0.9.9.9')
        args << '--priority' << (resource[:priority] || 0)
      end
    end

    begin
      Puppet::Util::Execution.execute([command(:chocolatey), *args])
    rescue Puppet::ExecutionFailure
      # add message about unable to execute
    end

    if @property_flush[:ensure] != :absent
      command = 'enable'
      command = 'disable' if @property_flush[:ensure] == :disabled
      begin
        Puppet::Util::Execution.execute([command(:chocolatey), 'sources', command, '--name', resource[:name]])
      rescue Puppet::ExecutionFailure
        # add message about unable to execute
      end
    end

    @property_hash.clear
    @property_hash = { :ensure => ( @property_flush[:ensure] )}  #if  @property_flush[:ensure] == :absent

    @property_flush.clear

    self.class.refresh_sources
    @property_hash = query
  end

end
