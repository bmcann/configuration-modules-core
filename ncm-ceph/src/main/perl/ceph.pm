# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;

use base qw(NCM::Component);

use LC::Exception;
use LC::Find;
use LC::File qw(copy makedir);

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use File::Basename;
use File::Path qw(make_path);
use File::Copy qw(move);
use JSON::XS;
use Readonly;
use Config::Tiny;

our $EC=LC::Exception::Context->new->will_store_all;

#set the working cluster, (if not given, use the default cluster 'ceph')
sub use_cluster {
    my ($self, $cluster) = @_;
    $cluster ||= 'ceph';
    if ($cluster ne 'ceph') {
        $self->error("Not yet implemented!\n"); 
        return 0;
    }
    $self->{cluster} = $cluster;
}

# run a command and return the output
sub run_command {
    my ($self, $command) = @_;
    my ($cmd_output, $cmd_err);
    my $cmd = CAF::Process->new($command, log => $self, 
        stdout => \$cmd_output, stderr => \$cmd_err);
    $cmd->execute();
    my $rc = $?;
    if (!$cmd_output) {
        $cmd_output = '<none>';
    }
    if ($rc) {
        $self->error("Command failed. Error Message: $cmd_err\n" , 
            "Command output: $cmd_output\n");
        $self->{lasterr} = $cmd_err;
        return 0;
    } else {
        $self->debug(2,"Command output: $cmd_output\n");
        if ($cmd_err) {
            $self->warn("Command stderr output: $cmd_err\n");
            $self->{lasterr} = $cmd_err;
        }    
    }
    return $cmd_output;
}

# run a command prefixed with ceph and return the output in json format
sub run_ceph_command {
    my ($self, $command) = @_;
    unshift (@$command, ('/usr/bin/ceph', '-f', 'json','--cluster', $self->{cluster}));
    return $self->run_command($command);
}

sub run_daemon_command {
    my ($self, $command) = @_;
    unshift (@$command, qw(/etc/init.d/ceph));
    return $self->run_command($command);
}
#checks for shell escapes
sub shell_escapes {
    my ($self, $cmd) = @_;
    if (grep(m{[;&>|"']}, @$cmd) ) {
        $self->error("Invalid shell escapes found in ", 
            join(" ", @$cmd));
        return 0;
    }
    return 1;
}
    
#Runs a command as the ceph user
sub run_command_as_ceph {
    my ($self, $command, $dir) = @_;
    
    $self->shell_escapes($command) or return 0; 
    if ($dir) {
        $self->shell_escapes($dir) or return 0;
        unshift (@$command, ('cd', $dir, '&&'));
    }
    $command = [join(' ',@$command)];
    unshift (@$command, qw(su - ceph -c));
    return $self->run_command($command);
}


# run a command prefixed with ceph-deploy and return the output (no json)
sub run_ceph_deploy_command {
    my ($self, $command, $dir, $overwrite) = @_;
    # run as user configured for 'ceph-deploy'
    if ($overwrite) {
        unshift (@$command, '--overwrite-conf');
    }
    unshift (@$command, ('/usr/bin/ceph-deploy', '--cluster', $self->{cluster}));
    return $self->run_command_as_ceph($command, $dir);
}

## Retrieving information of ceph cluster

# Gets the fsid of the cluster
sub get_fsid {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monhash = decode_json($jstr);
    return $monhash->{fsid};
}

# Gets the config of the cluster
sub get_global_config {
    my ($self, $file) = @_;
    my $cephcfg = Config::Tiny->new;
    $cephcfg = Config::Tiny->read($file);
    if (scalar(keys %$cephcfg) > 1) {
        $self->error("NO support for daemons not installed with ceph-deploy\n",
            "only global section expected, provided sections: ", keys %$cephcfg)
    }
    if (!$cephcfg->{global}) {
        $self->error("Not a valid config file found");
        return 0;
    }
    return $cephcfg->{global};
}

# Gets the OSD map
sub osd_hash {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(osd tree)]) or return 0;
    my $osdtree = decode_json($jstr);
    $jstr = $self->run_ceph_command([qw(osd dump)]) or return 0;
    my $osddump = decode_json($jstr);  

    # my %osdparsed = {};
}

# Matches the OSD with the underlying disk/path 
sub match_osd {
    my ($self, ) = @_;

# Gets the MON map
sub mon_hash {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monsh = decode_json($jstr);
    $jstr = $self->run_ceph_command([qw(quorum_status)]) or return 0;
    my $monstate = decode_json($jstr);
    my %monparsed = ();
    foreach my $mon (@{$monsh->{mons}}){
        $mon->{up} = $mon->{name} ~~ @{$monstate->{quorum_names}};
        $monparsed{$mon->{name}} = $mon; 
    }
    return \%monparsed;
}
# Gets the MSD map 
sub msd_hash {
     my ($self) = @_;
    # TODO implement
}       
## Processing and comparing between Quattor and Ceph

# Do a comparison of quattor config and the actual ceph config 
# for a given type (cfg, mon, osd, msd)
sub ceph_quattor_cmp {
    my ($self, $type, $quath, $cephh) = @_;
    foreach my $qkey (keys %{$quath}) {
        if (exists $cephh->{$qkey}) {
            my $pair = [$quath->{$qkey}, $cephh->{$qkey}];
            #check attrs and reconfigure
            $self->config_daemon($type, 'change', $qkey, $pair) or return 0;
            delete $cephh->{$qkey};
        } else {
            $self->config_daemon($type, 'add', $qkey, $quath->{$qkey}) or return 0;
        }
    }
    foreach my $ckey (keys %{$cephh}) {
        $self->config_daemon($type, 'del', $ckey, $cephh->{$ckey}) or return 0;
    }        
    return 1;
}

# Compare ceph config with the quattor cluster config
sub process_config {
    my ($self, $qconf) = @_;
    # Run only once?
    my $hosts = $qconf->{mon_initial_members};
    foreach my $host (@{$hosts}) {
        # Set config and make admin host
        $self->set_admin_host($qconf, $host) or return 0;
    }
    return 1;
}

# Compare ceph mons with the quattor mons
sub process_mons {
    my ($self, $qmons) = @_;
    my $cmons = $self->mon_hash() or return 0;
    return $self->ceph_quattor_cmp('mon', $qmons, $cmons);
}

# Compare cephs osd with the quattor osds
sub process_osds {
    my ($self, $qosds) = @_;
    my $cosds = $self->osd_hash() or return 0;
    return $self->ceph_quattor_cmp('osd', $qosds, $cosds);
}

# Compare cephs msd with the quattor msds
sub process_msds {
    my ($self, $qmsds) = @_;
    my $cmsds = $self->msd_hash() or return 0;
    return $self->ceph_quattor_cmp('msd', $qmsds, $cmsds);
}

# Move old config files to old dir with timestamp
sub move_to_old {
    my ($self, $filename) = @_;
    my $origdir = $self->{qtmp};
    my $olddir = $origdir . "old/";
    my $filepath = $origdir . $filename;
    
    if (!-d $olddir) {
        $self->error("Directory $olddir does not exists");
        return 0;
    }
    if (-e $filepath) {
        my $suff = ".old." . time();
        my $newfile = $olddir . $filename . $suff;
        $self->debug('3', "Moving file $filepath to $newfile");
        if (!move($filepath, $newfile)){ 
            $self->error("Moving $filepath to $newfile failed: $!");
            return 0;
        }
    } 
    return 1;
}  
    
# Pull config from host
sub pull_cfg {
    my ($self, $host) = @_;
    my $pullfile = $self->{cluster} . '.conf';
    my $hostfile = $pullfile . '.' . $host;
    $self->move_to_old($pullfile) or return 0;
    $self->run_ceph_deploy_command([qw(config pull), $host], $self->{qtmp}) or return 0;
    $self->move_to_old($hostfile) or return 0;

    move($self->{qtmp} . $pullfile, $self->{qtmp} .  $hostfile) or return 0;
    
    my $cephcfg = $self->get_global_config($self->{qtmp} . $hostfile) or return 0;

    return $cephcfg;    
}

# Push config to host
sub push_cfg {
    my ($self, $host, $overwrite) = @_;
    if ($overwrite) {
        return $self->run_ceph_deploy_command([qw(config push), $host],'',1 );
    }else {
        return $self->run_ceph_deploy_command([qw(config push), $host] );
    }     
}

# Makes the changes in the config file realtime by using ceph injectargs
sub inject_realtime {
    my ($self, $host, $changes) = @_;
    my @cmd;
    for my $param (keys %{$changes}) {
        @cmd = ('tell',"*.$host",'injectargs','--');
        my $keyvalue = "--$param=$changes->{$param}";
        $self->info("injecting $keyvalue realtime on $host");
        $self->run_ceph_command([@cmd, $keyvalue]);
    }
}
# Pulls config from host, compares it with quattor config and pushes the config back if needed
sub pull_compare_push {
    my ($self, $config, $host) = @_;
    my $cconf = $self->pull_cfg($host);
    if (!$cconf) {
        return $self->push_cfg($host);
        
    } else {
        $self->{comp} = 1;
        $self->{cfgchanges} = {};
        $self->debug(3, "Pulled config:", %$cconf);
        $self->ceph_quattor_cmp('cfg', $config, $cconf) or return 0;
        if ($self->{comp} == 1) {
            #Config the same, no push needed
            return 1;
        } elsif ($self->{comp} == -1) {
            $self->push_cfg($host,1) or return 0;
            $self->inject_realtime($host, $self->{cfgchanges}) or return 0;
        } else {# 0 already catched
            $self->error('No valid value returned after comparison');
            return 0;
        }
    }    
}
# Prepare the commands to change a global config entry
sub config_cfgfile {
    my ($self,$action,$name,$values) = @_;
    if ($name eq 'fsid') {
        if ($action ne 'change'){
            $self->error("config has no fsid!");
            return 0;
        } else {
            if ($values->[0] ne $values->[1]) {
                $self->error("config has different fsid!");
                return 0;
            } else {
                return 1
            }
        }
    }   
    if ($action eq 'add'){
        $self->info("$name added to config file\n");
        if (ref($values) eq 'ARRAY'){
            $values = join(',',@$values); 
        }
        $self->{comp} = -1;
        $self->{cfgchanges}->{$name} = $values;

    } elsif ($action eq 'change') {
        my $quat = $values->[0];
        my $ceph = $values->[1];
        if (ref($quat) eq 'ARRAY'){
            $quat = join(',',@$quat); 
        }
        #TODO: check if changes are valid
        if ($quat ne $ceph) {
            $self->info("$name changed from $ceph to $quat\n");
            $self->{comp} = -1;
            $self->{cfgchanges}->{$name} = $quat;
        }
    } elsif ($action eq 'del'){
        # TODO If we want to keep the existing configuration settings that are not in Quattor, 
        # we need to log it here. For now we expect that every used config parameter is in Quattor
        $self->error("$name not in quattor\n");
        #$self->info("$name deleted from config file\n");
        $self->{comp} = -1;
        return 0;
    } else {
        $self->error("Action $action not supported!");
        return 0;
    }
    return 1; 
}

# Prepare the commands to change/add/delete a monitor  
sub config_mon {
    my ($self,$action,$name,$daemonh) = @_;
    if ($action eq 'add'){
        my @command = qw(mon create);
        push (@command, $name);
        push (@{$self->{deploy_cmds}}, [@command]);
    } elsif ($action eq 'del') {
        my @command = qw(mon destroy);
        push (@command, $name);
        push (@{$self->{man_cmds}}, [@command]);
    } elsif ($action eq 'change') { #compare config
        my $quatmon = $daemonh->[0];
        my $cephmon = $daemonh->[1];
        # checking immutable attributes
        my @monattrs = ();
        foreach my $attr (@monattrs) {
            if ($quatmon->{$attr} ne $cephmon->{$attr}){
                $self->error("Attribute $attr of $name not corresponding\n");
                return 0;
            }
        }
        if ($cephmon->{addr} =~ /^0\.0\.0\.0:0/) { #Initial (unconfigured) member
               $self->config_mon('add', $quatmon);
        }
        if (($name eq $self->{hostname}) and ($quatmon->{up} xor $cephmon->{up})){
            my @command; 
            if ($quatmon->{up}) {
                @command = qw(start); 
            } else {
                @command = qw(stop);
            }
            push (@command, "mon.$name");
            push (@{$self->{daemon_cmds}}, [@command]);
        }
        my @donecmd = ('/usr/bin/ssh', $name, 'test','-e',"/var/lib/ceph/mon/$self->{cluster}-$name/done" );
        if (!$cephmon->{up} && !$self->run_command_as_ceph([@donecmd])) {
            # Node reinstalled without first destroying it
            $self->info("Monitor $name shall be reinstalled");
            return $self->config_mon('add',$name,$quatmon);
        }
    }
    else {
        $self->error("Action $action not supported!");
    }
    return 1;   
}

# Prepare the commands to change/add/delete an osd
sub config_osd {
    my ($self,$action,$name,$daemonh) = @_;
    # TODO implement
    if ($action eq 'add'){
    
    } elsif ($action eq 'del') {
   
    } else {

    } 
}

# Prepare the commands to change/add/delete an msd
sub config_msd {
    my ($self,$action,$name,$daemonh) = @_;
    # TODO implement
    if ($action eq 'add'){
    
    } elsif ($action eq 'del') {
    
    } else {

    } 
}


# Configure on a type basis
sub config_daemon {
    my ($self, $type,$action,$name,$daemonh) = @_;
    if ($type eq 'cfg'){
        $self->config_cfgfile($action,$name,$daemonh);
    }
    elsif ($type eq 'mon'){
        $self->config_mon($action,$name,$daemonh);
    }
    elsif ($type eq 'osd'){
        $self->config_osd($action,$name,$daemonh);
    }
    elsif ($type eq 'msd'){
        $self->config_msd($action,$name,$daemonh);
    } else {
        $self->error("No such type: $type\n");
    }
}

# Write the config file
sub write_config {
    my ($self, $cfg, $cfgfile ) = @_;
    my $tinycfg = Config::Tiny->new;
    my $config = { %$cfg };
    foreach my $key (%{$config}) {
        if (ref($config->{$key}) eq 'ARRAY'){ #For mon_initial_members
            $config->{$key} = join(',',@{$config->{$key}});
            $self->debug(3,"Array converted to string:", $config->{$key});
        }
    }
    $tinycfg->{global} = $config;
    if (!$tinycfg->write($cfgfile)) {
        $self->error("Could not write config file $cfgfile: $!", "Exitcode: $?\n"); 
        return 0;
    }
    $self->debug(2,"content written to config file $cfgfile\n");
    return 1;
}

# Deploy daemons 
sub do_deploy {
    my ($self) = @_;
    if ($self->{is_deploy}){ #Run only on deploy host(s)
        $self->info("Running ceph-deploy commands.\n");
        while (my $cmd = shift @{$self->{deploy_cmds}}) {
            $self->debug(1,@$cmd);
            $self->run_ceph_deploy_command($cmd) or return 0;
        }
    } else {
        $self->info("host is no deployhost, skipping ceph-deploy commands.\n");
        $self->{deploy_cmds} = [];
    }
    while (my $cmd = shift @{$self->{ceph_cmds}}) {
        $self->run_ceph_command($cmd) or return 0;
    }
    while (my $cmd = shift @{$self->{daemon_cmds}}) {
        $self->debug(1,"Daemon command:", @$cmd);
        $self->run_daemon_command($cmd) or return 0;
    }
    $self->print_man_cmds();
    return 1;
}

# Print out the commands that should be run manually
sub print_man_cmds {
    my ($self) = @_;
    if ($self->{man_cmds} && @{$self->{man_cmds}}) {
        $self->info("Commands to be run manually (as ceph user):\n");
        while (my $cmd = shift @{$self->{man_cmds}}) {
            $self->info(join(" ", @$cmd) . "\n");
        }
    }
}

#Set config and Make a temporary directory for push and pulls
sub init_qdepl {
    my ($self, $config) = @_;
    my $cephusr = $self->{cephusr};
    my $qdir = $cephusr->{homeDir} . '/ncm-ceph/' ;
    my $odir = $qdir . 'old/' ;
    make_path($qdir, $odir, {owner=>$cephusr->{uid}, group=>$cephusr->{gid}});

    $self->{qtmp} = $qdir; 
    
    $self->write_config($config,$cephusr->{homeDir} . '/' . $self->{cluster} . '.conf' ) or return 0; 
}
   
#Initialize array buckets
sub init_commands {
    my ($self) = @_;
    $self->{deploy_cmds} = [];
    $self->{ceph_cmds} = [];
    $self->{daemon_cmds} = [];
    $self->{man_cmds} = [];
}

#Checks if cluster is configured on this node.
#Prepares ceph ceploy if applicable 
#Fail if cluster not ready and no deploy hosts
sub cluster_ready_check {
    my ($self, $cluster) = @_;
    if ($self->{is_deploy}) { 
        # Check If something is not configured or there is no existing cluster 
        my $hosts = $cluster->{config}->{mon_initial_members};
        my $ok= 0;
        my $okhost;
        $self->{inner} = 1;
        foreach my $host (@{$hosts}) {
            if ($self->run_ceph_deploy_command([qw(gatherkeys), $host])) {
                $ok = 1;
                $okhost = $host;
                last;
            }    
        }
        if (!$ok) {
            # Manual commands for new cluster  
            # Push to deploy_cmds (and pre-run dodeploy) for automation, 
            # but take care of race conditions
            my @newcmd = qw(/usr/bin/ceph-deploy new);
            foreach my $host (@{$hosts}) {
                push (@newcmd, $host);
            }
            push (@{$self->{man_cmds}}, [@newcmd]);
            my @moncr = qw(/usr/bin/ceph-deploy mon create-initial);
            push (@{$self->{man_cmds}}, [@moncr]);
            return 0;
        } else {
            # Set config file in place and prepare ceph-deploy
            $self->init_qdepl($cluster->{config}) or return 0;
        }
    }    
    if (!$self->run_ceph_command([qw(status)])) {
        if ($self->{is_deploy}) {
            if (!$self->set_admin_host($cluster->{config},$self->{hostname}) 
                    || !$self->run_ceph_command([qw(status)])) {
                $self->error("Cannot connect to ceph cluster!\n"); #This should not happen
                return 0;
            } else {
                $self->debug(1,"Node ready to receive ceph-commands");
            }
        } else {
            $self->error("Cluster not configured and no ceph deploy host.." . 
                "Run on a deploy host!\n"); 
            return 0;
        }
    }
    my $fsid = $self->get_fsid();
    if ($cluster->{config}->{fsid} ne $fsid) {
        $self->error("fsid of $self->{cluster} not matching!\n", 
            "Quattor value: $cluster->{config}->{fsid}\n", 
            "Cluster value: $fsid\n");
        return 0;
    }
    return 1;
}

#Make all defined hosts ceph admin hosts (=able to run ceph commands)
#This is not (necessary) the same as ceph-deploy hosts!
# Also deploy config file
sub set_admin_host {
    my ($self, $config, $host) = @_;
    if ($self->{is_deploy}) {
        $self->pull_compare_push($config, $host) or return 0;
        my @admins=qw(admin);
        push(@admins, $host);
        $self->run_ceph_deploy_command(\@admins); 
    }
}
# Compare the configuration (and prepare commands) 
sub check_configuration {
    my ($self, $cluster) = @_;
    $self->init_commands();
    $self->process_config($cluster->{config}) or return 0;
    $self->process_mons($cluster->{monitors}) or return 0;
#    $self->process_osds($cluster->{osdhosts}) or return 0;
#    if ($cluster->{msds}) {
#        $self->process_msds($cluster->{msds}) or return 0;
#    }
    return 1;
}

#generate mon hosts
sub gen_mon_host {
    my ($self, $config, $domain) = @_;
    $config->{mon_host} = [];
    foreach my $host (@{$config->{mon_initial_members}}) {
        push (@{$config->{mon_host}},$host . '.' . $domain);
    }
}
           
sub Configure {
    my ($self, $config) = @_;
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    $self->{cephusr} = $config->getElement('/software/components/accounts/users/ceph')->getTree();
    my $group = $config->getElement('/software/components/accounts/groups/ceph')->getTree();
    $self->{cephusr}->{gid} = $group->{gid};
    $self->{hostname} = $netw->{hostname};
    foreach my $clus (keys %{$t->{clusters}}){
        $self->use_cluster($clus) or return 0;
        my $cluster = $t->{clusters}->{$clus};
        $self->{is_deploy} = $cluster->{deployhosts}->{$self->{hostname}} ? 1 : 0 ;
        $self->gen_mon_host($cluster->{config}, $netw->{domainname});
        if (!$self->cluster_ready_check($cluster)) {
            $self->print_man_cmds();
            return 0; 
        }       
        $self->debug(1,"checking configuration\n");
        $self->check_configuration($cluster) or return 0;
        $self->debug(1,"deploying commands\n");
        $self->do_deploy() or return 0; 
        $self->print_man_cmds();
        $self->debug(1,'Done');
        return 1;
    }
}


1; # Required for perl module!
