use strict;
use warnings;

use Test::More tests => 12;
use Telnet::Parse::Filter;

# This is private property
# Unauthorized Access Prohibited 
#
# User Access Verification
#
# Password:

my $answer;
my $filter1 = new Telnet::Parse::Filter(Scanning => 1);

$answer = $filter1->data(
    "This is private property\r\n".
    "Unauthorized Access Prohibited\r\n\r\n".
    "User Access Verification\r\n\r\n");
ok(!defined $answer, "Parse banner without giving any answer");

$answer = $filter1->data("\r\nPassword:");
is($filter1->auth_type(), "password", "Detect correct auth type: password");
ok($filter1->done(), "We are done");
ok(!$filter1->error(), "No error is set");


# This is private property
# Unauthorized Access Prohibited 
#
# User Access Verification
#
# Username:

my $filter2 = new Telnet::Parse::Filter(Scanning => 1);
$answer = $filter2->data(
    "This is private property\r\n".
    "Unauthorized Access Prohibited\r\n\r\n".
    "User Access Verification\r\n\r\n");
ok(!defined $answer, "Parse banner without giving any answer");

$answer = $filter2->data("\r\nUsername:");
is($filter2->auth_type(), "login", "Detect correct auth type: login");
ok($filter2->done(), "We are done");
ok(!$filter2->error(), "No error is set");

# Ubuntu 7.10
# tlb-desktop login:

my $filter3 = new Telnet::Parse::Filter(Scanning => 1);

$answer = $filter3->data("Ubuntu 7.10\r\n");
ok(!defined $answer, "Parse banner without giving any answer");

$answer = $filter3->data("\r\ntlb-desktop login:");
is($filter3->auth_type(), "login", "Detect correct auth type: login");
ok($filter3->done(), "We are done");
ok(!$filter3->error(), "No error are set");

