package Telnet::Parse::Constants;  
use strict;
use warnings;

our $VERSION = '1.00';

use base "Exporter";

our @EXPORT = qw(
    $SB_IS $SB_SEND $SB_REPLY $SB_NAME
    $BINT $ECHO $RCONN $SGA $AMSN $STATUS $TM $RCTE $OLW $OPS $OCRD
    $OHTS $OHTD $OFFD $OVTS $OVTD $OLFD $EASCII $LOGOUT $BMACRO $DET
    $SUPDUP $SUPDUPO $SENDLOC $TT $ENDREC $TACACS $OUTMARK $TLN $T3270R $X3PAD
    $NAWS $TSPEED $RFLOW $LM $XLOC $ENV $AUTH $ENCR $NENV $TN3270E
    $XAUTH $CHARSET $TRSP $COMPC $TSLE $TSTLS $KERMIT $SENDURL $FWDX
    $TPLOGON $TSLOGON $TPHEART
    $SE $NOP $DM $BRK $IP $AO $AYT $EC $EL $GA $SB
    $WILL $WONT $DO $DONT
    $IAC
    %telnet_codes
);

# Sub options commands
our $SB_IS    = "\x00"; #   0,
our $SB_SEND  = "\x01"; #   1, 
our $SB_REPLY = "\x02"; #   2, 
our $SB_NAME  = "\x03"; #   3, 

# http://www.scit.wlv.ac.uk/~jphb/comms/telnet.html
# Telnet Options
our $BINT    = "\x00"; #   0, Binary Transmission
our $ECHO    = "\x01"; #   1, Echo data
our $RCONN   = "\x02"; #   2, Reconnection
our $SGA     = "\x03"; #   3, Suppress Go Ahead
our $AMSN    = "\x04"; #   4, Approx Message Size Negotiation
our $STATUS  = "\x05"; #   5, Status
our $TM      = "\x06"; #   6, Timing Mark
our $RCTE    = "\x07"; #   7, Remote Controlled Trans and Echo
our $OLW     = "\x08"; #   8, Output Line Width
our $OPS     = "\x09"; #   9, Output Page Size
our $OCRD    = "\x0a"; #  10, Output Carriage-Return Disposition
our $OHTS    = "\x0b"; #  11, Output Horizontal Tab Stops
our $OHTD    = "\x0c"; #  12, Output Horizontal Tab Disposition
our $OFFD    = "\x0d"; #  13, Output Formfeed Disposition
our $OVTS    = "\x0e"; #  14, Output Vertical Tab Stops
our $OVTD    = "\x0f"; #  15, Output Vertical Tab Disposition
our $OLFD    = "\x10"; #  16, Output Linefeed Disposition
our $EASCII  = "\x11"; #  17, Extended ASCII
our $LOGOUT  = "\x12"; #  18, Logout
our $BMACRO  = "\x13"; #  19, Byte Macro
our $DET     = "\x14"; #  20, Data Entry Terminal
our $SUPDUP  = "\x15"; #  21, SUPDUP
our $SUPDUPO = "\x16"; #  22, SUPDUP Out
our $SENDLOC = "\x17"; #  23, Send Location
our $TT      = "\x18"; #  24, Terminal Type
our $ENDREC  = "\x19"; #  25, End of Record
our $TACACS  = "\x1a"; #  26, TACACS User Identification
our $OUTMARK = "\x1b"; #  27, Output Marking
our $TLN     = "\x1c"; #  28, Terminal Location Number
our $T3270R  = "\x1d"; #  29, Telnet 3270 Regime
our $X3PAD   = "\x1e"; #  30, X.3 PAD
our $NAWS    = "\x1f"; #  31, Negotiate About Window Size
our $TSPEED  = "\x20"; #  32, Terminal Speed
our $RFLOW   = "\x21"; #  33, Remote Flow Control
our $LM      = "\x22"; #  34, Linemode
our $XLOC    = "\x23"; #  35, X Display Location
our $ENV     = "\x24"; #  36, Environment
our $AUTH    = "\x25"; #  37, Authentication
our $ENCR    = "\x26"; #  38, Encryption
our $NENV    = "\x27"; #  39, New Environment Option
our $TN3270E = "\x28"; #  40, TN3270E
our $XAUTH   = "\x29"; #  41, XAuth
our $CHARSET = "\x2a"; #  42, Charset
our $TRSP    = "\x2b"; #  43, Telnet Remote Serial Port (RSP)
our $COMPC   = "\x2c"; #  44, Com Port Control
our $TSLE    = "\x2d"; #  45, Telnet Suppress Local Echo
our $TSTLS   = "\x2e"; #  46, Telnet Start TLS
our $KERMIT  = "\x2f"; #  47, Kermit
our $SENDURL = "\x30"; #  48, Send-URL
our $FWDX    = "\x31"; #  49, Forward X

# 50 -137 Unassigned
our $TPLOGON = "\x8a"; # 138, Telnet Pragma Logon
our $TSLOGON = "\x8b"; # 139, Telnet SSPI Logon
our $TPHEART = "\x8c"; # 140, Telnet Pragma Heartbeat

# Std. Telnet option.
our $SE      = "\xf0"; # 240, End of subnegotiation parameters 
our $NOP     = "\xf1"; # 241, No operation
our $DM      = "\xf2"; # 242, Data mark
our $BRK     = "\xf3"; # 243, Break
our $IP      = "\xf4"; # 244, Suspend, interrupt or abort
our $AO      = "\xf5"; # 245, Abort output
our $AYT     = "\xf6"; # 246, Are you there
our $EC      = "\xf7"; # 247, Erase character
our $EL      = "\xf8"; # 248, Erase line
our $GA      = "\xf9"; # 249, Go ahead
our $SB      = "\xfa"; # 250, Subnegotiation of the indicated option follows

# Command options
our $WILL    = "\xfb"; # 251, WILL -> DO|DONT
our $WONT    = "\xfc"; # 252, WONT -> DONT
our $DO      = "\xfd"; # 253, DO   -> WILL|WONT
our $DONT    = "\xfe"; # 254, DONT -> WONT

# Option start indicator 
our $IAC     = "\xff"; # 255 

our %telnet_codes = (
    chr(240) => { name => 'SE', support => 0},
    chr(241) => { name => 'NOP', support => 0},
    chr(242) => { name => 'Data Mark', support => 0},
    chr(243) => { name => 'Break', support => 0},
    chr(244) => { name => 'Interrupt Process', support => 0},
    chr(245) => { name => 'Abort output', support => 0},
    chr(246) => { name => 'Are You There', support => 0},
    chr(247) => { name => 'Erase character', support => 0},
    chr(248) => { name => 'Erase Line', support => 0},
    chr(249) => { name => 'Go ahead', support => 0},
    chr(250) => { name => 'SB', support => 0},
    chr(251) => { name => 'WILL', support => 0},
    chr(252) => { name => 'WONT', support => 0},
    chr(253) => { name => 'DO', support => 0},
    chr(254) => { name => 'DONT', support => 0},
    chr(255) => { name => 'IAC', support => 0},
    chr(0)   => { name => 'Binary Transmission', support => 0},
    chr(1)   => { name => 'Echo', support => 1},
    chr(2)   => { name => 'Reconnection', support => 0},
    chr(3)   => { name => 'Suppress Go Ahead', support => 1},
    chr(4)   => { name => 'Approx Message Size Negotiation', support => 0},
    chr(5)   => { name => 'Status', support => 0},
    chr(6)   => { name => 'Timing Mark', support => 0},
    chr(7)   => { name => 'Remote Controlled Trans and Echo', support => 0},
    chr(8)   => { name => 'Output Line Width', support => 0},
    chr(9)   => { name => 'Output Page Size', support => 0},
    chr(10)  => { name => 'Output Carriage-Return Disposition', support => 0},
    chr(11)  => { name => 'Output Horizontal Tab Stops', support => 0},
    chr(12)  => { name => 'Output Horizontal Tab Disposition', support => 0},
    chr(13)  => { name => 'Output Formfeed Disposition', support => 0},
    chr(14)  => { name => 'Output Vertical Tabstops', support => 0},
    chr(15)  => { name => 'Output Vertical Tab Disposition', support => 0},
    chr(16)  => { name => 'Output Linefeed Disposition', support => 0},
    chr(17)  => { name => 'Extended ASCII', support => 0},
    chr(18)  => { name => 'Logout', support => 0},
    chr(19)  => { name => 'Byte Macro', support => 0},
    chr(20)  => { name => 'Data Entry Terminal', support => 0},
    chr(21)  => { name => 'SUPDUP', support => 0},
    chr(22)  => { name => 'SUPDUP Output', support => 0},
    chr(23)  => { name => 'Send Location', support => 0},
    chr(24)  => { name => 'Terminal Type', support => 0},
    chr(25)  => { name => 'End of Record', support => 0},
    chr(26)  => { name => 'TACACS User Identification', support => 0},
    chr(27)  => { name => 'Output Marking', support => 0},
    chr(28)  => { name => 'Terminal Location Number', support => 0},
    chr(29)  => { name => 'Telnet 3270 Regime', support => 0},
    chr(30)  => { name => 'X.3 PAD', support => 0},
    chr(31)  => { name => 'Negotiate About Window Size', support => 0},
    chr(32)  => { name => 'Terminal Speed', support => 0},
    chr(33)  => { name => 'Remote Flow Control', support => 0},
    chr(34)  => { name => 'Linemode', support => 0},
    chr(35)  => { name => 'X Display Location', support => 0},
    chr(36)  => { name => 'Environment Option', support => 0},
    chr(37)  => { name => 'Authentication Option', support => 0},
    chr(38)  => { name => 'Encryption Option', type => "\xfe"},
    chr(39)  => { name => 'New Environment Option', support => 0},
    chr(40)  => { name => 'TN3270E', support => 0},
    chr(41)  => { name => 'XAUTH', support => 0},
    chr(42)  => { name => 'CHARSET', support => 0},
    chr(43)  => { name => 'Telnet Remote Serial Port (RSP)', support => 0},
    chr(44)  => { name => 'Com Port Control Option', support => 0},
    chr(45)  => { name => 'Telnet Suppress Local Echo', support => 0},
    chr(46)  => { name => 'Telnet Start TLS', support => 0},
    chr(47)  => { name => 'KERMIT', support => 0},
    chr(48)  => { name => 'SEND-URL', support => 0},
    chr(49)  => { name => 'FORWARD_X', support => 0},
);

1;

