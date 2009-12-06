use strict;
use warnings;

use Test::More tests => 7;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths  => [{login => 'mylogin', password => 'mypassword'}],
  Cmds   => ['pwd', 'ls -l', 'exit'],
);

$answer = $filter->data("\r\n\r\nThis is private property\r\n"
    ."Unauthorized Access Prohibited\r\n");
$answer = $filter->data("\r\n\r\nUser Access Verification\r\n"
    ."Username: ");
cmp_ok($answer, "eq", "mylogin\r\n", "Parse password and give password");
cmp_ok($filter->type(), "eq", "Cisco::IOS", "Detect correct type: Cisco::IOS");

$answer = $filter->data("a");
$answer = $filter->data("dmi");
$answer = $filter->data("na");
$answer = $filter->data("lk");
ok(!defined $answer, "Get echo crap back and ignore it");
$answer = $filter->data("\r\nPassword: ");
cmp_ok($answer, "eq", "mypassword\r\n", "Parse password and give password");

$answer = $filter->data("\r\n\r\nrdkba8kxc020#");
cmp_ok($answer, "eq", "pwd\r\n", "Match prompt and send back first cmd");

$answer = $filter->data("\r\n\r\nrdkba8kxc020#");
cmp_ok($answer, "eq", "ls -l\r\n", "Match prompt and send back second cmd");

$answer = $filter->data("\r\n\r\nrdkba8kxc020#");
cmp_ok($answer, "eq", "exit\r\n", "Match prompt and send back second cmd");

$answer = $filter->data("\r\n");

