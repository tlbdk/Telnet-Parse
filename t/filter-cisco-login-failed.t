use strict;
use warnings;

use Test::More tests => 6;
use Telnet::Parse::Filter;

# 
# This is private property
# Unauthorized Access Prohibited 
#
# User Access Verification
#
# Password: 
# Password: 
# Password: 
# % Bad passwords
#
#

my $answer;

my $filter = new Telnet::Parse::Filter(
  Prompt => 'auto', # Auto detect prompt
  Auths   => [
    { password => 'mypassword' },
    { password => 'mypassword2' },
    { password => 'mypassword3' },
    { password => 'mypassword4' },
  ],
  Cmds   => ['pwd', 'ls -l'],
);

$answer = $filter->data(
    "This is private property\r\n".
    "Unauthorized Access Prohibited\r\n\r\n".
    "User Access Verification\r\n\r\n");

ok(!defined $answer, "Parse banner without giving any answer");
is($filter->type(), "Cisco::IOS", "Detect correct type: Cisco::IOS");

$answer = $filter->data("\r\nPassword:");
is($answer, "mypassword\r\n", "Parse password string and try with first password");

$answer = $filter->data("\r\nPassword:");
is($answer, "mypassword2\r\n", "Parse password string and try with second password");

$answer = $filter->data("Password:");
is($answer, "mypassword3\r\n", "Parse password string and try with third password");

$answer = $filter->data("\r\n% Bad passwords");
is_deeply($filter->auths(), [ { password => 'mypassword4', type => 'auto' } ],
    "Get last line and check that we only have the last auth left");

