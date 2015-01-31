use strict;
use warnings;
use Test::More;
use Test::Quattor;

use helper;
use NCM::Component::systemd;

$CAF::Object::NoAction = 1;

# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');

=pod

=head1 DESCRIPTION

Test C<NCM::Component::Systemd::Service::Unit> module for systemd.

=head2 EXPORTS

Test exports

=cut

use NCM::Component::Systemd::Service::Unit qw(:targets $DEFAULT_TARGET :types $DEFAULT_STARTSTOP $DEFAULT_STATE);
is_deeply([$TARGET_DEFAULT, $TARGET_RESCUE, $TARGET_MULTIUSER, $TARGET_GRAPHICAL,
           $TARGET_POWEROFF, $TARGET_REBOOT],
          [qw(default rescue multi-user graphical poweroff reboot)],
          "exported TARGET names");
is($DEFAULT_TARGET, $TARGET_MULTIUSER, "multiuser is default target");

is_deeply([$TYPE_SYSV, $TYPE_SERVICE, $TYPE_TARGET],
          [qw(sysv service target)],
           "exported TYPES names");

is($DEFAULT_STARTSTOP, 1, "DEFAULT startstop is $DEFAULT_STARTSTOP"); 
is($DEFAULT_STATE, "on", "DEFAULT state is $DEFAULT_STATE");

=head2 new

Test creation of Unit instance

=cut

my $services = {};
my $unit = NCM::Component::Systemd::Service::Unit->new(services => $services, log => $cmp);
isa_ok($unit, "NCM::Component::Systemd::Service::Unit",
        "NCM::Component::Systemd::Service::Unit instance created");

=pod

=head2 service_text

Test the generating text message from service details

=cut

my $svc = {
    name => "test_del",
    state => "on",
    type => "service",
    startstop => 0,
    targets => ["rescue"],
};

is($unit->service_text($svc), 
   "service test_del (state on startstop 0 type service targets rescue)", 
   "Generate string of service details");

=pod

=head2 init_cache

Test the init method

=pod

my ($u_c, $u_a, $d_c) = $unit->init_cache();
is_deeply($u_c, {
    service => {},
    target => {},    
}, "unit_cache initialised");

is_deeply($u_a, {
    service => {},
    target => {},    
}, "unit_alias initialised");

is_deeply($d_c, {
    deps => {},
    rev => {},    
}, "dependency_cache initialised");



=head2 make_cache_alias

Generate the cache and alias for services and targets.

=cut

use cmddata::service_systemctl_list_show_gen_full_el7_ceph021_load;

# reset errors, $cmp is logger of $unit
$cmp->{ERROR} = 0;

my ($service_cache, $service_alias) = $unit->make_cache_alias($TYPE_SERVICE);

is($cmp->{ERROR}, 0, 'No errors while processing cache and alias for $TYPE_SERVICE');
is(scalar keys %$service_cache, 145,
    'Found 145 non-alias services via make_cache_alias $TYPE_SERVICE');
is(scalar keys %$service_alias, 144, 
    'Found 144 service aliases via make_cache_alias $TYPE_SERVICE');

# Tests for
# sshd@ base instance service, different from sshd service
ok($service_cache->{'sshd@'}->{baseinstance}, 'sshd@ base instance found');
ok($service_cache->{'sshd'}->{show}, 'sshd service found with show data');
ok(! $service_cache->{'sshd'}->{baseinstance}, 'sshd service is not a base instance');

# getty@tty1 instance vs getty@ instance unit-file
ok($service_cache->{'getty@'}->{baseinstance}, 'getty@ base instance found');
ok(! $service_cache->{'getty@'}->{instance}, 'getty@ base instance has no instance data');

ok(exists($service_cache->{'getty@tty1'}), 'getty@tty1 instance found');
ok(! $service_cache->{'getty@tty1'}->{baseinstance}, 'getty@tty1 is not a base instance');
is($service_cache->{'getty@tty1'}->{instance}, 'tty1', 'getty@tty1 instance has instance data');

# some aliases
is($service_alias->{'dbus-org.freedesktop.hostname1'}, 'systemd-hostnamed', 
    "dbus-org.freedesktop.hostname1 is alias of systemd-hostnamed");
is($service_alias->{'systemd-hostnamed'}, 'systemd-hostnamed', 
    "systemd-hostnamed is alias of itself (all services are in alias list)");
ok(! $service_cache->{'dbus-org.freedesktop.hostname1'}, 
    "Pure alias dbus-org.freedesktop.hostname1 is not in cache");

my ($target_cache, $target_alias) = $unit->make_cache_alias($TYPE_TARGET);

is($cmp->{ERROR}, 0, 'No errors while processing cache and alias for $TYPE_TARGET');
is(scalar keys %$target_cache, 45, 
    'Found 45 non-alias targets via make_cache_alias $TYPE_TARGET');
is(scalar keys %$target_alias, 54, 
    'Found 54 target aliases via make_cache_alias $TYPE_TARGET');


=pod

=head2 current_services

Get services via the make_cache_alias
                                                                                                                                                      
=cut                                                                                                                                                  

my $name;
my $cs = $unit->current_services();

is($cmp->{ERROR}, 0, 'No errors while processing current_services');

is(scalar keys %$cs, 137, 
   'Found 137 non-alias services via current_services');

$name = 'nrpe';
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"on", "Service $name state disabled");
is($svc->{type}, "service", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");

# on, but failed to start
$name = 'rc-local';
$svc = $cs->{$name};
is($svc->{name}, $name, "Service $name name matches");
is($svc->{state},"on", "Service $name state disabled");
is($svc->{type}, "service", "Service $name type sysv");
ok($svc->{startstop}, "Service $name startstop true");
is_deeply($svc->{targets}, ["multi-user"], "Service $name targets");


done_testing();
