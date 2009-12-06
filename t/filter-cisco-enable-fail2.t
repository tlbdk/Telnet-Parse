use strict;
use warnings;

use Test::More tests => 11;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths   => [{login => 'mylogin', password => 'mypassword', enable => ['myenable','myenable2']}],
  Cmds   => ['terminal length 0', 'en', 'show running-config'],
);

# 
# This is private property
# Unauthorized Access Prohibited
# 
# User Access Verification
# 
# Username: mylogin
# Password:
# 
# core10.dkba>en
# Password:
# % Access denied

$answer = $filter->data("\r\n\r\nThis is private property\r\nUnauthorized Access Prohibited\r\n");
ok(!defined $answer, "Parse banner without giving any answer");
$answer = $filter->data("\r\nUser Access Verification");
cmp_ok($filter->type(), "eq", "Cisco::IOS", "Detect correct type: Cisco::IOS");

$answer = $filter->data("\r\n\r\nUsername:");
cmp_ok($answer, "eq", "mylogin\r\n", "Parse username and give login");
$answer = $filter->data("\r\nPassword:");
cmp_ok($answer, "eq", "mypassword\r\n", "Parse password and give password");
$answer = $filter->data("\r\npsdkkaefxb005>");
cmp_ok($answer, "eq", "terminal length 0\r\n", "Detect terminal and set length to 0");
$answer = $filter->data("\r\npsdkkaefxb005>");
cmp_ok($answer, "eq", "en\r\n", "Set enable mode");
$answer = $filter->data("\r\nPassword:");
cmp_ok($answer, "eq", "myenable\r\n", "Parse password and give enable password");
$answer = $filter->data("\r\n% Access denied\r\npsdkkaefxb005>");
cmp_ok($answer, "eq", "en\r\n", "Retry enable mode");
$answer = $filter->data("\r\nPassword:");
cmp_ok($answer, "eq", "myenable2\r\n", "Parse password and give next enable password");
$answer = $filter->data("\r\npsdkkaefxb005#");
cmp_ok($answer, "eq", "show running-config\r\n", "Get running config");
is_deeply($filter->auth(), { login => 'mylogin', enable=>'myenable2', 
        password=>'mypassword' }, "Auth struct was correct");
