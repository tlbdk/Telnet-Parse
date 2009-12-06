use strict;
use warnings;

use Test::More tests => 10;

use Telnet::Parse::Constants;
use Telnet::Parse qw(telnet_parse telnet_dump telnet_options);

use Data::Dumper;

my %options = (
    'local' => {
        $TSPEED => { options => [38400, 38400], type => $WILL },
        $TT     => { options => ["xterm"], type => $WILL },
        $NAWS   => { options => [123,23], type => $WILL },
    },
    remote => {
        $STATUS => { options => [sub { 1; }], type => $DO },
    }
);

my $answer; my $expect; my @data;

# Test sending new options defined by user
$expect = 
    "$IAC$DO$STATUS".
    "$IAC$WILL$TT".
    "$IAC$WILL$NAWS".
    "$IAC$WILL$TSPEED";
$answer = telnet_options(\%options);
cmp_ok($answer, "eq", $expect, "We got the right options back");

# Retying to send options
$answer = telnet_options(\%options);
ok(!defined $answer, "Options already sent, dont send again");

# Set new user defined option
$options{remote}{$SGA} = { type => $DO };
$expect = "$IAC$DO$SGA"; 
$answer = telnet_options(\%options);
cmp_ok($answer, "eq", $expect, "Send new SGA option");

# Retying to send options
$answer = telnet_options(\%options);
ok(!defined $answer, "Options already sent, dont send again");

# Option parsing with sub option respose and $DO on already sent $WILL 
@data = ( 
    "$IAC$DO$TT",
    "$IAC$DO$TSPEED",
    "$IAC$DO$XLOC",
    "$IAC$DO$NENV",
    "$IAC$DO$NAWS",
    "$IAC$WILL$STATUS",
    "$IAC$WILL$SGA");
$expect = 
    "$IAC$WONT$XLOC".
    "$IAC$WONT$NENV".
    "$IAC$SB$NAWS\x00\x7b\x00\x25$IAC$SE";

$answer = telnet_options(\%options, @data);
cmp_ok($answer, "eq", $expect, "Test options parsing 1");
#telnet_dump("Ans", $answer);

$answer = telnet_options(\%options);
ok(!defined $answer, "Options already sent, dont send again");

# Option parsing with only sub options 
@data = (
    "$IAC$SB$TSPEED\x01$IAC$SE",
    "$IAC$SB$TT\x01$IAC$SE");
$expect =
    "$IAC$SB$TSPEED\x00\x33\x38\x34\x30\x30\x2c\x33\x38\x34\x30\x30$IAC$SE".
    "$IAC$SB$TT\x00\x78\x74\x65\x72\x6d$IAC$SE";
$answer = telnet_options(\%options, @data);
cmp_ok($answer, "eq", $expect, "Test options parsing 2");
#telnet_dump("answer",$answer) if $answer;

# Retest with same suboptions 
$answer = telnet_options(\%options, @data);
ok(!defined $answer, "Options sent dont send again");

# Test echo and rflow options
@data = (
    "$IAC$DO$ECHO",
    "$IAC$DO$RFLOW");
$expect =
    "$IAC$WONT$ECHO".
    "$IAC$WONT$RFLOW";
$answer = telnet_options(\%options, @data);
cmp_ok($answer, "eq", $expect, "Test options parsing 3");

# Test echo options
@data = (
    "$IAC$WILL$ECHO");
$expect = "$IAC$DONT$ECHO";
$answer = telnet_options(\%options, @data);
cmp_ok($answer, "eq", $expect, "Test options parsing 4");

