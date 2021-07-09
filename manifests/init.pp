# @summary Create the required cron job and scripts for sending Puppet Events
#
# This class will create the cron job that executes the event management script.
# It also creates the event management script in the required directory.
#
# @example
#   include common_events
class common_events (
  Optional[String]            $pe_username = undef,
  Optional[Sensitive[String]] $pe_password = undef,
  Optional[String]            $pe_token    = undef,
) {

  # Account for the differences in Puppet Enterprise and open source
  if $facts[pe_server_version] != undef {
    $owner          = 'pe-puppet'
    $group          = 'pe-puppet'
  }
  else {
    notify { 'Non-PE':
      message => "Error: This module is intended for use with Puppet Enterprise only.",
    }
  }

  if (
    ($pe_token == undef)
    and
    ($pe_username == undef or $pe_password == undef)
  ) {
    $authorization_failure_message = @(MESSAGE/L)
    Please set both 'pe_username' and 'pe_password' \
    if you are not using a pre generated PE authorization \
    token in the 'pe_token' parameter
    |-MESSAGE
    fail($authorization_failure_message)
  }

  cron { 'collect_common_events':
    ensure  => 'present',
    command => @("COMMAND"/L),
      ${settings::confdir}/common_events/collect_api_events.rb \
      ${settings::confdir}/common_events \
      ${settings::modulepath} \
      ${settings::confdir}/common_events/processors.d
      |-COMMAND
    user    => 'root',
    minute  => '*/2',
    require => [
      File["${settings::confdir}/common_events/collect_api_events.rb"],
      File["${settings::confdir}/common_events/events_collection.yaml"]
    ],
  }

  file { "${settings::confdir}/common_events":
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    recurse => 'remote',
    source  => 'puppet:///modules/common_events/lib',
  }

  file { "${settings::confdir}/common_events/processors.d":
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    require => File["${settings::confdir}/common_events"],
  }

  file { "${settings::confdir}/common_events/events_collection.yaml":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    require => File["${settings::confdir}/common_events"],
    content => epp('common_events/events_collection.yaml'),
  }

  file { "${settings::confdir}/common_events/collect_api_events.rb":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File["${settings::confdir}/common_events"],
    source  => 'puppet:///modules/common_events/collect_api_events.rb',
  }
}
