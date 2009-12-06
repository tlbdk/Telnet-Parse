use strict;
use warnings;

use Test::More tests => 9;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths  => [{login => 'mylogin', password => 'mypassword'}],
  Cmds   => ['terminal length 0', 'show running-config', 'exit'],
);

$answer = $filter->data("\r\n\r\nThis is private property\r\nUnauthorized Access Prohibited\r\n");
ok(!defined $answer, "Parse banner without giving any answer");
$answer = $filter->data("\r\nUser Access Verification");
cmp_ok($filter->type(), "eq", "Cisco::IOS", "Detect correct type: Cisco::IOS");

$answer = $filter->data("\r\n\r\nUsername:");
cmp_ok($answer, "eq", "mylogin\r\n", "Parse username and give login");

$answer = $filter->data("\r\nPassword:");
cmp_ok($answer, "eq", "mypassword\r\n", "Parse password and give password");

$answer = $filter->data("\r\nrdkba8kxc020# ");
cmp_ok($answer, "eq", "terminal length 0\r\n", "Parse prompt and send first cmd");
cmp_ok($filter->prompt(), "eq", qr/(?m:^[\r\w.-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)/, "Detect correct prompt");

$answer = $filter->data("\r\nrdkba8kxc020# ");
cmp_ok($answer, "eq", "show running-config\r\n", "Parse prompt and send second cmd");

my $data = "
Building configuration...

Current configuration : 8899 bytes
!
! Last configuration change at 21:27:45 CET+1 Wed Nov 21 2007 by adminalk
! NVRAM config last updated at 09:14:34 CET+1 Wed Nov 14 2007 by adminhfel
!
!
...
end
rdkba8kxc020#\n";
$data =~ s/\n/\r\n/g;

my $expect = $data;
$expect =~ s/\r\n/\n/gs;
$expect =~ s/\nrdkba8kxc020#$//s;
$expect =~ s/^\n//; $expect =~ s/\n$//s;

$answer = $filter->data($data);
cmp_ok($answer, "eq", "exit\r\n", "Get back last command");
cmp_ok(($filter->results())[1], "eq", $expect, "Get config data");

