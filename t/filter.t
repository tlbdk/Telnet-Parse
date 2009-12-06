use strict;
use warnings;

use Test::More tests => 16;
use Telnet::Parse::Filter;

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths  => [{login => 'mylogin', password => 'mypassword'}],
  Cmds   => ['pwd', 'ls -l'],
);

$answer = $filter->data("\r\nLinux 2.6.24-rc3 (localhost.localdomain) (5)\r\n\r\n");
ok(!defined $answer, "Parse banner without giving any answer");
cmp_ok($filter->type(), "eq", "Linux", "Detect correct type: Linux");
cmp_ok($filter->extras('kernelversion'), "eq", "2.6.24-rc3", "Detect kernel version");

$answer = $filter->data("tlbc login:\r\n");
cmp_ok($answer, "eq", "mylogin\r\n", "Parse login string and give login");

$answer = $filter->data("Password:\r\n\r\n");
cmp_ok($answer, "eq", "mypassword\r\n", "Parse password and give password");

$answer = $filter->data("\r\nLast login: Sat Nov 17 23:35:40 WET 2007 from ");
ok(!defined $answer, "Parse last login line and dont give any answer");

$answer = $filter->data("localhost.localdomain on pts/4\r\n[hk\@tlbc ~]\$");
cmp_ok($answer, "eq", "pwd\r\n", 
    "Parse more last login line and a prompt, so answer with command");
cmp_ok($filter->cmds(), "==", 1, "1 command left in the queue");
cmp_ok($filter->prompt(), "eq", qr/(\n)?\[.+?[\~\w\d]+\]\$/, "Detect correct type, Bash like");
cmp_ok($filter->extras('lastlogin'), "eq", 'Sat Nov 17 23:35:40 WET 2007', 
    "Got correct data");

$answer = $filter->data("\r\n/home/hk\r\n[hk\@tlbc ~]\$");
cmp_ok($answer, "eq", "ls -l\r\n", "Parse answer and prompt, answer next command");
cmp_ok(($filter->results())[0], "eq", "/home/hk", "Answer was only the path");

$answer = $filter->data("\r\ntotal 0\r\n");
ok(!defined $answer, "Parse first part of cmd result, and don't answer");
$answer = $filter->data("-rw-r--r-- 1 root root 0 2007-11-19 13:49 test\r\n");
ok(!defined $answer, "Parse second part of cmd result, and don't answer");
$answer = $filter->data("[tlb\@tlbc hk]\$");
cmp_ok(($filter->results())[1], "eq", "total 0\n-rw-r--r-- 1 root root 0 2007-11-19 13:49 test", 
    "Parse answer and prompt");
cmp_ok($filter->cmds(), "==", 0, "No more commands in the queue");

