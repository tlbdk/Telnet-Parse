use strict;
use warnings;

use Test::More tests => 3;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths  => [{ password => 'mypassword' }],
  Cmds   => ['terminal length 0', 'show running-config', 'exit'],
);

$answer = $filter->data("\r\n\r\nThis is private property\r\nUnauthorized Access Prohibited\r\n");
ok(!defined $answer, "Parse banner without giving any answer");
$answer = $filter->data("\r\nUser Access Verification");
cmp_ok($filter->type(), "eq", "Cisco::IOS", "Detect correct type: Cisco::IOS");

$answer = $filter->data("\r\n\r\nUsername:");
is($filter->error(), 'No more logins to try', "Parse username and give login");

