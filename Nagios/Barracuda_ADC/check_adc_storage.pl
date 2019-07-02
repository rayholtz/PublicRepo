#!/usr/bin/perl -w 
# nagios: -epn
############################## check_adc_storage ##############
# Version : 1.0
# Date : July 2, 2019
# Author  : Ray Holtz
# Licence : GPL - http://www.fsf.org/licenses/gpl.txt
# Original Script: check_snmp_mem v1.1 by Patrick Proy
# This script was originally by Patrick Proy, but was heavily modified for a different use by Ray Holtz
#################################################################
#
# Help : ./check_adc_storage.pl -h
#

use strict;
use Net::SNMP;
use Getopt::Long;

# Nagios specific

use lib "/usr/lib/nagios/plugins";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

# SNMP Datas
# Barracuda Storage

my $firmware_storage    = ".1.3.6.1.4.1.20632.5.99.1.4.3.0";  # 
my $maillog_storage     = ".1.3.6.1.4.1.20632.5.99.1.4.4.0";  #
my @barr_oids		= ($firmware_storage,$maillog_storage);

# Globals

my $Version='1.0';

my $o_host = 	undef; 		# hostname
my $o_community = undef; 	# community
my $o_port = 	161; 		# port
my $o_help=	undef; 		# wan't some help ?
my $o_verb=	undef;		# verbose mode
my $o_version=	undef;		# print version
my $o_netsnmp=	1;		# Check with netsnmp (default)
my $o_warn=	undef;		# warning level option
my $o_crit=	undef;		# Critical level option
my $o_perf=	undef;		# Performance data option
my $o_cache=	undef;		# Include cached memory as used memory
my $o_timeout=  undef; 		# Timeout (Default 5)
my $o_version2= undef;          # use snmp v2c
# SNMPv3 specific
my $o_login=	undef;		# Login for snmpv3
my $o_passwd=	undef;		# Pass for snmpv3
my $v3protocols=undef;	# V3 protocol list.
my $o_authproto='md5';		# Auth protocol
my $o_privproto='des';		# Priv protocol
my $o_privpass= undef;		# priv password

# functions
sub p_version { print "check_snmp_mem version : $Version\n"; }

sub print_usage {
    print "Usage: $0 [-v] -H <host> -C <snmp_community> [-2] | (-l login -x passwd [-X pass -L <authp>,<privp>])  [-p <port>] -w <warn level> -c <crit level> [-I|-N|-E] [-f] [-m] [-t <timeout>] [-V]\n";
}

sub isnnum { # Return true if arg is not a number
  my $num = shift;
  if ( $num =~ /^(\d+\.?\d*)|(^\.\d+)$/ ) { return 0 ;}
  return 1;
}

sub round ($$) {
    sprintf "%.$_[1]f", $_[0];
}

sub help {
   print "\nSNMP Memory Monitor for Nagios version ",$Version,"\n";
   print "(c)2004-2006 to my cat Ratoune - Author: Patrick Proy\n\n";
   print_usage();
   print <<EOT;
-v, --verbose
   print extra debugging information (including interface list on the system)
-h, --help
   print this help message
-H, --hostname=HOST
   name or IP address of host to check
-C, --community=COMMUNITY NAME
   community name for the host's SNMP agent (implies SNMP v1 or v2c with option)
-2, --v2c
   Use snmp v2c
-l, --login=LOGIN ; -x, --passwd=PASSWD
   Login and auth password for snmpv3 authentication 
   If no priv password exists, implies AuthNoPriv 
-X, --privpass=PASSWD
   Priv password for snmpv3 (AuthPriv protocol)
-L, --protocols=<authproto>,<privproto>
   <authproto> : Authentication protocol (md5|sha : default md5)
   <privproto> : Priv protocole (des|aes : default des) 
-P, --port=PORT
   SNMP port (Default 161)
-w, --warn=INTEGER | INT,INT
   warning level for memory in percent (0 for no checks) 
     Default (-N switch) : comma separated level for Real Memory and Swap 
     -I switch : warning level
-c, --crit=INTEGER | INT,INT
   critical level for memory in percent (0 for no checks)
     Default (-N switch) : comma separated level for Real Memory and Swap 
     -I switch : critical level
-N, --netsnmp (default)
   check linux memory & swap provided by Net SNMP 
-m, --memcache
   include cached memory in used memory (only with Net-SNMP)
-I, --cisco
   check cisco memory (sum of all memory pools)
-E, --hp
   check HP proccurve memory
-f, --perfdata
   Performance data output
-t, --timeout=INTEGER
   timeout for SNMP in seconds (Default: 5)
-V, --version
   prints version number
EOT
}

# For verbose output
sub verb { my $t=shift; print $t,"\n" if defined($o_verb) ; }

# Get the alarm signal (just in case snmp timout screws up)
$SIG{'ALRM'} = sub {
     print ("ERROR: Alarm signal (Nagios time-out)\n");
     exit $ERRORS{"UNKNOWN"};
};
sub check_options {
    Getopt::Long::Configure ("bundling");
	GetOptions(
   	'v'	=> \$o_verb,		'verbose'	=> \$o_verb,
        'h'     => \$o_help,    	'help'        	=> \$o_help,
        'H:s'   => \$o_host,		'hostname:s'	=> \$o_host,
        'p:i'   => \$o_port,   		'port:i'	=> \$o_port,
        'C:s'   => \$o_community,	'community:s'	=> \$o_community,
	'l:s'	=> \$o_login,		'login:s'	=> \$o_login,
	'x:s'	=> \$o_passwd,		'passwd:s'	=> \$o_passwd,
	'X:s'	=> \$o_privpass,		'privpass:s'	=> \$o_privpass,
	'L:s'	=> \$v3protocols,		'protocols:s'	=> \$v3protocols,   
	't:i'   => \$o_timeout,       	'timeout:i'     => \$o_timeout,
	'V'	=> \$o_version,		'version'	=> \$o_version,
	'N'	=> \$o_netsnmp,		'netsnmp'	=> \$o_netsnmp,
        '2'     => \$o_version2,        'v2c'           => \$o_version2,
        'c:s'   => \$o_crit,            'critical:s'    => \$o_crit,
        'w:s'   => \$o_warn,            'warn:s'        => \$o_warn,
        'm'   	=> \$o_cache,           'memcache'      => \$o_cache,
        'f'     => \$o_perf,            'perfdata'      => \$o_perf
    );
    if (defined ($o_help) ) { help(); exit $ERRORS{"UNKNOWN"}};
    if (defined($o_version)) { p_version(); exit $ERRORS{"UNKNOWN"}};
    if ( ! defined($o_host) ) # check host and filter 
	{ print "No host defined!\n";print_usage(); exit $ERRORS{"UNKNOWN"}}
    # check snmp information
    if ( !defined($o_community) && (!defined($o_login) || !defined($o_passwd)) )
	  { print "Put snmp login info!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if ((defined($o_login) || defined($o_passwd)) && (defined($o_community) || defined($o_version2)) )
	  { print "Can't mix snmp v1,2c,3 protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if (defined ($v3protocols)) {
	  if (!defined($o_login)) { print "Put snmp V3 login info with protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	  my @v3proto=split(/,/,$v3protocols);
	  if ((defined ($v3proto[0])) && ($v3proto[0] ne "")) {$o_authproto=$v3proto[0];	}	# Auth protocol
	  if (defined ($v3proto[1])) {$o_privproto=$v3proto[1];	}	# Priv  protocol
	  if ((defined ($v3proto[1])) && (!defined($o_privpass))) {
	    print "Put snmp V3 priv login info with priv protocols!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	}
	if (defined($o_timeout) && (isnnum($o_timeout) || ($o_timeout < 2) || ($o_timeout > 60))) 
	  { print "Timeout must be >1 and <60 !\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
	if (!defined($o_timeout)) {$o_timeout=5;}
	#Check Warning and crit are present
    if ( ! defined($o_warn) || ! defined($o_crit))
 	{ print "Put warning and critical values!\n"; print_usage(); exit $ERRORS{"UNKNOWN"}}
#}else { print "Warning and Critical **ARE** defined\n";}


 if (defined($o_netsnmp)) {

      if ( isnnum($o_warn) || isnnum($o_crit)) 
	{ print "Numeric value for warning or critical !\n";print_usage(); exit $ERRORS{"UNKNOWN"} }
      if ( ($o_crit != 0) && ($o_warn > $o_crit) ) 
        { print "warning <= critical ! \n";print_usage(); exit $ERRORS{"UNKNOWN"}}
    }
  
}
########## MAIN #######

check_options();

# Check gobal timeout if snmp screws up
if (defined($TIMEOUT)) {
  verb("Alarm at $TIMEOUT");
  alarm($TIMEOUT);
} else {
  verb("no timeout defined : $o_timeout + 10");
  alarm ($o_timeout+10);
}
# Connect to host
my ($session,$error);
if ( defined($o_login) && defined($o_passwd)) {
  # SNMPv3 login
  if (!defined ($o_privpass)) {
  verb("SNMPv3 AuthNoPriv login : $o_login, $o_authproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -timeout          => $o_timeout
    );  
  } else {
    verb("SNMPv3 AuthPriv login : $o_login, $o_authproto, $o_privproto");
    ($session, $error) = Net::SNMP->session(
      -hostname   	=> $o_host,
      -version		=> '3',
      -username		=> $o_login,
      -authpassword	=> $o_passwd,
      -authprotocol	=> $o_authproto,
      -privpassword	=> $o_privpass,
	  -privprotocol => $o_privproto,
      -timeout      => $o_timeout
    );
  }
} else {
   if (defined ($o_version2)) {
     # SNMPv2 Login
	 verb("SNMP v2c login");
	 ($session, $error) = Net::SNMP->session(
	-hostname  => $o_host,
	    -version   => 2,
	-community => $o_community,
	-port      => $o_port,
	-timeout   => $o_timeout
     );
   } else {
    # SNMPV1 login
	verb("SNMP v1 login");
    ($session, $error) = Net::SNMP->session(
       -hostname  => $o_host,
       -community => $o_community,
       -port      => $o_port,
       -timeout   => $o_timeout
    );
  }
}
if (!defined($session)) {
   printf("ERROR opening session: %s.\n", $error);
   exit $ERRORS{"UNKNOWN"};
}

# Global variable
my $resultat=undef;

########### Barracuda Storage Check ############
if (defined ($o_netsnmp)) {

  # Get NetSNMP memory values
  $resultat = (Net::SNMP->VERSION lt 4) ?
		$session->get_request(@barr_oids)
		:$session->get_request(-varbindlist => \@barr_oids);
  
 if (!defined($resultat)) {
     printf("ERROR: netsnmp : %s.\n", $session->error);
     $session->close;
     exit $ERRORS{"UNKNOWN"};
     }

 my ($firmused,$mailused)=(undef,undef);

 $firmused= $$resultat{$firmware_storage};
 $mailused= $$resultat{$maillog_storage};
   
 $firmused =~ s/\%//g;
 $mailused =~ s/\%//g;

 my $n_status="OK";
 my $n_output="Firmware: $firmused% used, Maillog is $mailused% used.";

 if ((($o_crit!=0)&&($o_crit <= $firmused)) || (($o_crit!=0)&&($o_crit <= $mailused))) {
    $n_output .= "  One of them is > the critical limit of " . $o_crit ;
    $n_status="CRITICAL";
    } else {
 if ((($o_warn!=0)&&($o_warn <= $firmused)) || (($o_warn!=0)&&($o_warn <= $mailused))) {
    $n_output .= "  One of them is > the warning limit of " . $o_warn ;
    $n_status="WARNING";
    }
 }

  $n_output .= " ; ".$n_status;

  $session->close;
  print "$n_output \n";
  exit $ERRORS{$n_status};

}
