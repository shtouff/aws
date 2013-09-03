#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(:config gnu_getopt);
use JSON;
use Data::Dumper;

my %instances = do "config.pl";

my $ids;
my ($opt_action, $opt_group, $opt_verbose);

sub stop_group
{
	my $group = shift;
	my $ret = 0;
	
	foreach ( keys $instances{$group} ) {	
		$ids .= " " . $instances{$group}{$_};
		print "will stop instance $_ ($instances{$group}{$_})\n" if defined($opt_verbose)
	}
	
	my $json_result = qx( aws ec2 stop-instances --instance-ids $ids );
	if ($? != 0) {
		warn "WARN: $json_result\n";
		return 1;
	};
	my $result = decode_json $json_result;
	
	if (exists($result->{StoppingInstances})) {
		foreach (@{$result->{StoppingInstances}}) {
			my $id = $_->{InstanceId};
			my $state = $_->{CurrentState}{Name};
			
			if ($state ne "stopping") {
				warn "WARN: $id is in $state state\n";
				$ret = 1;
			}
		}
	}
	
	$ret;	
}

sub start_group
{
	my $group = shift;
	my $ret = 0;
	
	foreach ( keys $instances{$group} ) {	
		$ids .= " " . $instances{$group}{$_};
		print "will start instance $_ ($instances{$group}{$_})\n";
	}
	
	my $json_result = qx( aws ec2 start-instances --instance-ids $ids );
	if ($? != 0) {
		warn "WARN: $json_result\n";
		return 1;
	};
	my $result = decode_json $json_result;
	
	if (exists($result->{StartingInstances})) {
		foreach (@{$result->{StartingInstances}}) {
			my $id = $_->{InstanceId};
			my $state = $_->{CurrentState}{Name};
			
			if ($state ne "pending") {
				warn "WARN: $id is in $state state\n";
				$ret = 1;
			}
		}
	}
	
	$ret;	
}

if (
	!GetOptions(
		"action=s"    => \$opt_action,
		'a=s'         => \$opt_action,
		"group=s"     => \$opt_group,
		'g=s'         => \$opt_group,
		"verbose"     => \$opt_verbose,
		"v"           => \$opt_verbose
	)
  )
{
	die "getopt failed";
}

if ( ! defined($opt_group)) {
	die "please give a group";
} elsif (! exists $instances{$opt_group}) {
	die "no such group"
}

if (! defined($opt_action)) {
	die "please give an action"
} elsif ($opt_action eq "start") {
	start_group($opt_group);
} elsif ($opt_action eq "stop") {
	stop_group($opt_group);
} else {
	die "no such action";
}
