use strict;
use warnings;

use Test::More tests => 3;

use Telnet::Parse::Constants;
use Telnet::Parse qw(telnet_parse telnet_dump telnet_options);

use Data::Dumper;

my %options = (
    'local' => {
        $ECHO => { type => $WILL }
    },
    remote => {
        $ECHO => { type => $DO }
    },
);

my $answer; my $expect; my @data;

$expect = "$IAC$DO$ECHO".
          "$IAC$WILL$ECHO";
$answer = telnet_options(\%options);
cmp_ok($answer, "eq", $expect, "We got the right options back");

# Retying to send options
$answer = telnet_options(\%options);
ok(!defined $answer, "Options already sent, dont send again");

@data = (
    "$IAC$WILL$ECHO",
    "$IAC$DO$ECHO",
);
$answer = telnet_options(\%options, @data);
ok(!defined $answer, "Test options parsing 1");

