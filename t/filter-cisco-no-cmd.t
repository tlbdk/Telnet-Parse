use strict;
use warnings;

use Test::More tests => 6;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths  => [{login => 'mylogin', password => 'mypassword'}],
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
ok($filter->done(), "We are done");
ok(!$filter->error(), "No errors are set");

