use strict;
use warnings;

use Test::More tests => 5;

use Telnet::Parse::Constants;
use Telnet::Parse qw(telnet_parse telnet_dump telnet_options);

use Data::Dumper;

my %options = (
    'local' => {
    },
    remote => {
        $SGA => { type => $DO },
    }
);

my $answer; my $expect; my @data;

# Test sending new options defined by user
$expect = "$IAC$DO$SGA";
$answer = telnet_options(\%options);
cmp_ok($answer, "eq", $expect, "We got the right options back");

# Retying to send options
$answer = telnet_options(\%options);
ok(!defined $answer, "Options already sent, dont send again");

# Option parsing with sub option respose and $DO on already sent $WILL 
@data = (
    "$IAC$WILL$ECHO",
    "$IAC$WILL$SGA",
    "$IAC$DO$TT",
    "$IAC$DO$NAWS",
);
$expect =
    "$IAC$DONT$ECHO".
    "$IAC$WONT$TT".
    "$IAC$WONT$NAWS";
$answer = telnet_options(\%options, @data);
cmp_ok($answer, "eq", $expect, "Test options parsing 1");
#telnet_dump("", $answer) if defined $answer;

$answer = telnet_options(\%options);
ok(!defined $answer, "Options already sent, dont send again");

@data = (
    "$IAC$DONT$NAWS",
    "$IAC$WONT$ECHO",
);
$answer = telnet_options(\%options, @data);
ok(!defined $answer, "Test options parsing 3");
telnet_dump("Ans:", $answer) if $answer;

