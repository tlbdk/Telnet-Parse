use strict;
use warnings;

use Test::More tests => 10;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths   => [{ password => 'mypassword', enable => ['myenable','myenable2']}],
  Cmds   => ['terminal length 0', 'en', 'show running-config'],
);

$answer = $filter->data("\r\n\r\nThis is private property\r\nUnauthorized Access Prohibited\r\n");
ok(!defined $answer, "Parse banner without giving any answer");
$answer = $filter->data("\r\nUser Access Verification");
is($filter->type(), "Cisco::IOS", "Detect correct type: Cisco::IOS");

$answer = $filter->data("\r\n\r\nPassword:");
is($answer, "mypassword\r\n", "Parse password and give password");
$answer = $filter->data("\r\npsdkkaefxb005>");
is($answer, "terminal length 0\r\n", "Detect terminal and set length to 0");
$answer = $filter->data("\r\npsdkkaefxb005>");
is($answer, "en\r\n", "Set enable mode");
$answer = $filter->data("\r\nPassword:");
is($answer, "myenable\r\n", "Parse password and give enable password");
$answer = $filter->data("\r\nSorry\r\npsdkkaefxb005>");
is($answer, "en\r\n", "Retry enable mode");
$answer = $filter->data("\r\nPassword:");
is($answer, "myenable2\r\n", "Parse password and give next enable password");
$answer = $filter->data("\r\npsdkkaefxb005#");
is($answer, "show running-config\r\n", "Get running config");
is_deeply($filter->auth(), { enable=>'myenable2', 
        password=>'mypassword' }, "Auth struct was correct");
