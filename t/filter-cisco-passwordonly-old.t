use strict;
use warnings;

use Test::More tests => 11;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths   => [
    {password => 'mypassword1', enable => ['myenable']},
    {password => 'mypassword2', enable => ['myenable']},
    {password => 'mypassword3', enable => ['myenable']},
  
  ],
  Cmds   => ['terminal length 0', 'en', 'show running-config'],
);


# Enter password: 
#
# Enter password: 
#
# Enter password:
#
# --More--

$answer = $filter->data("\r\n\r\nCisco Systems, Inc. Console\r\n\r\n\r\n\r\n");
ok(!defined $answer, "Parse banner without giving any answer");

$answer = $filter->data("Enter password:");
cmp_ok($answer, "eq", "mypassword1\r\n", "Parse password and give password");

$answer = $filter->data("Enter password:");
cmp_ok($answer, "eq", "mypassword2\r\n", "Parse password and give password");

$answer = $filter->data("Enter password:");
cmp_ok($answer, "eq", "mypassword3\r\n", "Parse password and give password");

#cmp_ok($filter->type(), "eq", "Cisco::IOS", "Detect correct type: Cisco::IOS");
$answer = $filter->data("\r\npsdkkaefxb005>");
cmp_ok($answer, "eq", "terminal length 0\r\n", "Detect terminal and set length to 0");
$answer = $filter->data("\r\npsdkkaefxb005>");
cmp_ok($answer, "eq", "en\r\n", "Set enable mode");
$answer = $filter->data("\r\nPassword:");
cmp_ok($answer, "eq", "myenable\r\n", "Parse password and give enable password");
$answer = $filter->data("\r\npsdkkaefxb005#");
cmp_ok($answer, "eq", "show running-config\r\n", "Get running config");
$answer = $filter->data("The Config File...");
$answer = $filter->data("\r\n--More--");
cmp_ok($answer, "eq", " ", "Send space on --More--");
$answer = $filter->data("More Config file");
$answer = $filter->data("\r\npsdkkaefxb005#");

is_deeply([$filter->results()], ['', '', "The Config File...\nMore Config file"], 
    "Result struct was correct");

is_deeply($filter->auth(), { enable=>'myenable', 
        password=>'mypassword3' }, "Auth struct was correct");
