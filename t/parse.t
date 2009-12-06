use strict;
use warnings;

use Test::More tests => 36;

use Telnet::Parse::Constants;
use Telnet::Parse qw(telnet_parse);

my ($text, $left, @options);

# Check we can parse simple text
($text, $left, @options) = telnet_parse("Hello");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", "", "No data was left");
cmp_ok(@options, "==", 0, "No options where defined");

# Check that we support linebreaks 
($text, $left, @options) = telnet_parse("Hello\n\rHello");
cmp_ok($text, "eq", "Hello\n\rHello", "Text is correct");
cmp_ok($left, "eq", "", "No data was left");
cmp_ok(@options, "==", 0, "No options where defined");

# Check we support escaping of $IAC
($text, $left, @options) = telnet_parse("Hello${IAC}${IAC}Hello");
cmp_ok($text, "eq", "Hello${IAC}Hello", "Text is correct");
cmp_ok($left, "eq", "", "No data was left");
ok(@options == 0, "No options where defined");

# Check we support half options 1 char
($text, $left, @options) = telnet_parse("Hello${IAC}");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", $IAC, "Data was left");
ok(@options == 0, "No options where defined");

# Check we support half options 2 char
($text, $left, @options) = telnet_parse("Hello${IAC}${DO}");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", "$IAC$DO", "Data was left");
ok(@options == 0, "No options where defined");

# Check we support prefix options
($text, $left, @options) = telnet_parse("${IAC}${DO}${SGA}Hello");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", "", "Data was left");
cmp_ok($options[0], "eq", "$IAC$DO$SGA", "No options where defined");

# Check we support postfix options
($text, $left, @options) = telnet_parse("Hello${IAC}${DO}${SGA}");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", "", "Data was left");
cmp_ok($options[0], "eq", "$IAC$DO$SGA", "No options where defined");

# Check we embeded support options
($text, $left, @options) = telnet_parse("Hello${IAC}${DO}${SGA}Hello");
cmp_ok($text, "eq", "HelloHello", "Text is correct");
cmp_ok($left, "eq", "", "Data was left");
cmp_ok($options[0], "eq", "$IAC$DO$SGA", "No options where defined");

# Check we support half sub options
($text, $left, @options) = telnet_parse("Hello${IAC}${SB}${TT}");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", "$IAC$SB$TT", "No data was left");
ok(@options == 0, "No options where defined");

# Check we embeded support sub options
($text, $left, @options) 
    = telnet_parse("Hello${IAC}${SB}${TT}${SB_IS}xterm${IAC}${SE}Hello");
cmp_ok($text, "eq", "HelloHello", "Text is correct");
cmp_ok($left, "eq", "", "No data was left");
cmp_ok($options[0], "eq", "${IAC}${SB}${TT}${SB_IS}xterm${IAC}${SE}", 
    "No options where defined");

# Check we support prefix sub options
($text, $left, @options) 
    = telnet_parse("${IAC}${SB}${TT}${SB_IS}xterm${IAC}${SE}Hello");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", "", "No data was left");
cmp_ok($options[0], "eq", "${IAC}${SB}${TT}${SB_IS}xterm${IAC}${SE}", 
    "No options where defined");

# Check we support prefix sub options
($text, $left, @options) 
    = telnet_parse("Hello${IAC}${SB}${TT}${SB_IS}xterm${IAC}${SE}");
cmp_ok($text, "eq", "Hello", "Text is correct");
cmp_ok($left, "eq", "", "No data was left");
cmp_ok($options[0], "eq", "${IAC}${SB}${TT}${SB_IS}xterm${IAC}${SE}", 
    "No options where defined");

