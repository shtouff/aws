#!/usr/bin/perl -w

############################################################################    
#                                                                          #
# (C) COMUTO Rémi Paulmier <remi.paulmier@blablacar.com>                   #
#                                                                          #
#  This script helps to generate the Cisco prefix-list frome the list      #
#  of AWS advertised prefix available here:                                #
#   https://forums.aws.amazon.com/forum.jspa?forumID=126&start=0           #
#                                                                          #
############################################################################

use strict;
use Getopt::Std;

sub load_prefixes_from_file
{
	my $_file = shift;
	my $_prefixes = shift;
	
	open(LIST, "<$_file") or die ("can't read $_file");
    
	while (<LIST>) {
		chomp;
		if (/^(((2(5[0-5]|[0-4][0-9])|[01]?[0-9][0-9]?)\.){3}(2(5[0-5]|[0-4][0-9])|[01]?[0-9][0-9]?)(\/(3[012]|[12]?[0-9])))$/) {
			push @$_prefixes, $_;
		}
	}
}

my %opts;
my $runtime = { 
               'prefixes' => [],
               #'maxmask' => 28,
               'maxmask' => 32,
               #'pl-name' => 'FROM-AWS-PUBLIC'
               'pl-name' => 'PL-AS7224-IN'
              };

getopts("f:", \%opts);

if ( exists($opts{'f'}) ) {
	# loads domains from file
	load_prefixes_from_file($opts{'f'}, $runtime->{'prefixes'});
}

map { 
	my ($network, $netmask) = /([0-9.]+)\/([0-9]+)/;
	
	if ( $netmask <= $runtime->{'maxmask'} ) {
		print "ip prefix-list $runtime->{'pl-name'} permit $network/$netmask";
		
		if ( $netmask < $runtime->{'maxmask'} ) {
			print " le $runtime->{'maxmask'}";
		}
		print "\n";
	} else {
		print STDERR "prefix too small: $network/$netmask\n";
	}	
} @{$runtime->{'prefixes'}};

	
