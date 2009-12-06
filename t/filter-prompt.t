use strict;
use warnings;

use Test::More tests => 6;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths  => [{login => 'mylogin', password => 'mypassword'}],
  Cmds   => ['pwd'],
);

$answer = $filter->data("\r\nLinux 2.6.24-rc3 (localhost.localdomain) (5)\r\n\r\n");
ok(!defined $answer, "Parse banner without giving any answer");
cmp_ok($filter->type(), "eq", "Linux", "Detect correct type: Linux");
cmp_ok($filter->extras('kernelversion'), "eq", "2.6.24-rc3", "Detect kernel version");

$answer = $filter->data("tlbc login:\r\n");
cmp_ok($answer, "eq", "mylogin\r\n", "Parse login string and give login");

$answer = $filter->data("Password:\r\n\r\n");
cmp_ok($answer, "eq", "mypassword\r\n", "Parse password and give password");

$answer = $filter->data("Type help or '?' for a list of available commands.\r\nfcami001> ");
cmp_ok($answer, "eq", "pwd\r\n", "Parse prompt and send command");

