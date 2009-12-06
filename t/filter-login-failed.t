use strict;
use warnings;

use Test::More tests => 7;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths  => [
    { login => 'mylogin', password => 'mypassword' },
    { login => 'mylogin2', password => 'mypassword2' },
    { login => 'mylogin3', password => 'mypassword3' },
  ],
  Cmds   => ['pwd', 'ls -l'],
);

$answer = $filter->data("\r\nLinux 2.6.24-rc3 (localhost.localdomain) (5)\r\n\r\n");
ok(!defined $answer, "Parse banner without giving any answer");
cmp_ok($filter->type(), "eq", "Linux", "Detect correct type: Linux");
cmp_ok($filter->extras('kernelversion'), "eq", "2.6.24-rc3", "Detect kernel version");

$answer = $filter->data("\r\ntlbc login:");
cmp_ok($answer, "eq", "mylogin\r\n", "Parse login string and try with first login");

$answer = $filter->data("\r\nLogin incorrect\r\ntlbc login:");
cmp_ok($answer, "eq", "mylogin2\r\n", "Parse parse login and try with second login");

$answer = $filter->data("Password:");
cmp_ok($answer, "eq", "mypassword2\r\n", "Parse password and give password");

$answer = $filter->data("\r\nLogin incorrect\r\ntlbc login:");
cmp_ok($answer, "eq", "mylogin3\r\n", "Parse last login and give login");

