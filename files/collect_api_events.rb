#!/opt/puppetlabs/puppet/bin/ruby
require 'find'
require 'yaml'

require_relative 'api/events'
require_relative 'api/orchestrator'
require_relative 'events_collection/lockfile'
require_relative 'util/common_events_http'
require_relative 'util/pe_http'

def main(confdir, modulepaths, statedir)

  begin
    lockfile = CommonEvents::Lockfile.new(statedir)
    settings = YAML.safe_load(File.read("#{confdir}/events_collection.yaml"))
    if lockfile.already_running?
      puts 'already running'
    else
      lockfile.write_lockfile
      orchestrator_client = Orchestrator.new('localhost', username: settings['pe_username'], password: settings['pe_password'], token: settings['pe_token'], ssl_verify: false)
      puts orchestrator_client.get_jobs(limit: 1)
      # Find any compatible reports
      # Reports should be in /lib/reports/common_events
    end
  rescue => exception
    puts exception
  ensure
    lockfile.remove_lockfile
  end
end

if $PROGRAM_NAME == __FILE__
  confdir     = ARGV[0] || '/etc/puppetlabs/puppet/common_events'
  modulepaths = ARGV[1] || '/etc/puppetlabs/code/environments/production/modules:/etc/puppetlabs/code/environments/production/site:/etc/puppetlabs/code/modules:/opt/puppetlabs/puppet/modules'
  statedir    = ARGV[2] || '/etc/puppetlabs/puppet/common_events/processors.d'
  main(confdir, modulepaths, statedir)
end
