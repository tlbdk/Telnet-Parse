package Telnet::Parse;  
use strict;
use warnings;

use Telnet::Parse::Constants;
use Carp;

our $VERSION = '1.00';

=head1 NAME

Telnet::Parse - A module to parse telnet data and options

=head1 DESCRIPTION

This module makes it easy to work with telnet data and provides function for
doing option parsing, data encoding/decoding. Unlike Net::Telnet and other 
modules like it, the actual handling of sockets is left to other modules as
this module only works with data.

=head1 SYNOPSIS
  
  use Telnet::Parse;
  # FIXME: Make normal telnet socket and get sample working

  my ($text, $left, @options);
  while(1) {
      my $data = $sock->read(1000);

      telnet_parse($data);
      ($newtext, $left, @newoptions) = parse($left.$data);
      $text .= $newtext;

      # Answer what options we like to use
      my $buf = telnet_options(\@options, $newoptions);
      $sock->send($buf) if $buf;

      if($text =~ /login:/) {
          $sock->send("myusername\r\n");
      
      } elsif($text =~ /Password:/) {
          $sock->send("mypassword\r\n");
      }
  }
  

=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT_OK = qw(telnet_options telnet_parse telnet_dump telnet_decode);

=item telnet_parse($date) 

# FIXME: Fill out

=cut

sub telnet_parse {
    my ($data) = @_;
    # FIXME: Make tests for parsing Escaped chars
    # FIXME: Make tests for the other stuff as well.
    my @strs = ($data =~ /(
         (?:$IAC$SB.+?$IAC$SE) # Match subnegotiation
        |(?:$IAC$SB.+$) # Match half a subnegotiation
        |(?:$IAC$IAC) # Escaped IAC char
        |(?:$IAC[^$SB]{2}) # Match normal negotiation
        |(?:$IAC[^$SB]$) # Match half a normal negotiation
        |(?:$IAC$) # Match half a normal negotiation
        |(?:[^$IAC]+) # Match telnet text
        )/sgx);

    # Check if the last option was incomplete 
    my $left = '';
    if(@strs and $strs[-1] =~ /^$IAC[^$IAC]?/) {
        if($strs[-1] !~ /
            (?:$IAC[^$SB]{2}) # Match normal negotiation
            |(?:$IAC$SB.+?$IAC$SE) # Match subnegotiation
            /sx) {
            $left = pop(@strs);
        }
    }  
    #} elsif($str =~ /^\x0d[^\x0a]$/) {
    
    # Sort text from options
    my @options;
    my $text = '';
    foreach my $str (@strs) {
        # Deescape $IAC
        if($str =~ /^$IAC$IAC$/) {
            $text .= $IAC;
        # Deescape CR
        } elsif($str =~ /^\x0d\x00$/) {
            $text .= "\x0d";
        } elsif($str =~ /^$IAC/) {
            push(@options, $str);
        } else {
            $text .= $str;
        }
    }
    
    return ($text, $left, @options);
}


=item telnet_options 

# FIXME: Fill out

=cut

# Returns the options set in this round
sub telnet_options {
    my ($current, @options) = @_;
    my $buf;
    
    # Find options that need sending on both remote and local. 
    foreach my $option (sort keys %{$current->{remote}}) {
        # Option has already been negotiated 
        if(exists $current->{result}{remote}{$option}) {
        
        } elsif(my $status = $current->{remote}{$option}{type}) {
            $buf .= $IAC.$status.$option;
            $current->{result}{remote}{$option} = $status;
        }
    }
    foreach my $option (sort keys %{$current->{local}}) {
        # Option has already been negotiated 
        if(exists $current->{result}{local}{$option}) {
        
        } elsif(my $status = $current->{local}{$option}{type}) {
            $buf .= $IAC.$status.$option;
            $current->{result}{local}{$option} = $status;
        }
    }

    foreach my $str (@options) {
        my ($status, $option, $args) = ($str =~ /^.(.)(.)(.*)$/s);
       
        # Handle sub option negotiation
        if($status eq $SB) {
            # Skip sub options we have not defined 
            if(!defined $current->{local}{$option} 
                    and !defined $current->{remote}{$option}) {
                next;
            }
            # Sub options receives  
            if($args =~ /^$SB_IS(.*?)$IAC$SE$/) {
                if($option eq $STATUS) {
                    my $cb = $current->{local}{$option}{options}[0]; 
                    $cb->call($1);
                }
            # Sub options sends 
            } elsif($args =~ /^$SB_SEND$IAC$SE$/) {
                if($option eq $TT) {
                    my $term = 'xterm';

                    if($current->{local}{$option}{options}) {
                        $term = $current->{local}{$option}{options}[0]; 
                    }
                    
                    if(!$current->{local}{$option}{negotiated}) {
                        $buf .= "$IAC$SB$TT$SB_IS$term$IAC$SE";
                        $current->{local}{$option}{negotiated} = 1;
                    }
                
                } elsif($option eq $TSPEED) {
                    my ($speed1, $speed2) = (38400,38400); # Defaults
                     
                    if($current->{local}{$option}{options}) {
                        #print Dumper($options{local});
                        $speed1 = $current->{local}{$option}{options}[0]; 
                        $speed2 = $current->{local}{$option}{options}[1]; 
                    }

                    # negotiated 
                    if(!$current->{local}{$option}{negotiated}) {
                        $buf .= "$IAC$SB$TSPEED$SB_IS$speed1,$speed2$IAC$SE";
                        $current->{local}{$option}{negotiated} = 1;
                    }
                }
            
            } else {
                #telnet_dump("ERROR:Could not parse status", "$SB_IS$IAC$SE");
                telnet_dump("ERROR:Could not parse status", $args);
            }

        } elsif($status eq $DO) {
            # Option has already been negotiated
            if(exists $current->{result}{local}{$option}) {
                # We said DO and remote said WILL 
                if($current->{result}{local}{$option} eq $WILL) { 
                    if($option eq $NAWS) {
                        # FIXME: Set sane defaults
                        # FIXME: Read size from $client (width, hight)
                        my $num = pack("nn", 123, 37);
                        # Telnet encode FIXME: move to std. function
                        $num =~ s/$IAC/$IAC$IAC/;
                        $buf .= $IAC.$SB.$NAWS.$num.$IAC.$SE;
                    }
                }
                
            # Remote says DO and we WILL
            } elsif(exists $current->{local}{$option} 
                    and $current->{local}{$option} eq $WILL) {
                $buf .= $IAC.$WILL.$option;
                $current->{result}{local}{$option} = $WILL;

            # Remote says DO and we WONT
            } else {
                $buf .= $IAC.$WONT.$option;
                $current->{result}{local}{$option} = $WONT;
            }
        
        } elsif($status eq $DONT) {
            # Remote says DONT and we say WONT
            if(!exists $current->{result}{local}{$option}) {
                $buf .= $IAC.$WONT.$option;
            }
            $current->{result}{local}{$option} = $WONT;

        } elsif($status eq $WILL) {
            # Option has already been negotiated
            if(exists $current->{result}{remote}{$option}) {
                # We said DO and remote said WILL 
                if($current->{result}{remote}{$option} eq $DO) { 
                    if($option eq $NAWS) {
                        # FIXME: Set sane defaults
                        # FIXME: Read size from $client (width, hight)
                        my $num = pack("nn", 123, 37);
                        # Telnet encode FIXME: move to std. function
                        $num =~ s/$IAC/$IAC$IAC/;
                        $buf .= $IAC.$SB.$NAWS.$num.$IAC.$SE;
                    }
                }
            # Remote says WILL and we said DO 
            } elsif(exists $current->{remote}{$option} 
                    and $current->{remote}{$option} eq $DO) {
                $buf .= $IAC.$DO.$option;
                $current->{result}{remote}{$option} = $DO;

            # Remote says WILL and we say DONT
            } else {
                $buf .= $IAC.$DONT.$option;
                $current->{result}{remote}{$option} = $DONT;
            }
        
        } elsif($status eq $WONT) {
            # Remote says WONT and we say DONT
            if(!exists $current->{result}{remote}{$option}) {
                $buf .= $IAC.$DONT.$option;
            }
            $current->{result}{remote}{$option} = $WONT;
        }
    }

    return $buf; 
}

=item telnet_decode($header, $str)

Function that decodes telnet date by converting line ending to local form and 
removes all control/escape characters, like xterm color codes, etc.

=cut

sub telnet_decode {
    my ($str) = @_;
    
    # cat | perl -ne 'map { print sprintf("\\x%02x", ord($_)); } /(.)/g; print "\n";'
    # http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
    # http://www.termsys.demon.co.uk/vtansi.htm
    # http://en.wikipedia.org/wiki/ASCII
    # TODO: Functions using CSI , ordered by the final character(s) + the rest
    $str =~ s/
        (?:\x1b\x5b[^\x6d]*\x6d) # All xterm color codes
        #    |(?:\x1b\x5f.*?\x1b\x5c) # Application Program-Control functions
        |(?:\x1b\x50.*?\x1b\x5c) # Device-Control functions
        |(?:\x1b\x20[\x46\x47\x4c\x4d\x4e]) # 7-8-bit ctrls and ANSI conformance levels
        |(?:\x1b[\x37\x38\x3d\x3e\x46\x63\x6c # Other VT100
            \x6d\x6e\x6f\x7c\x7d\x7e])
        |(?:\x1b\x23[\x33\x34\x35\x36\x38]) # DEC
        |(?:\x1b\x25[\x40\x47]) # Select charset ISO 8859-1, UTF-8
        |(?:\x1b[\x44\x45\x48\x4d\x4e\x4f\x50\x56 # C1 (8-Bit) Ctrl char
            \x57\x58\x5a\x5b\x5c\x5d\x5e\x5f])
        |(?:\x1b[\x28\x29\x2a\x2b] # Designating chars sets VT100-VT220+
            [\x30\x41\x42\x34\x43\x35\x52
            \x51\x4b\x59\x45\x36\x5a\x48\x37\x43])
        |(?:[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f]) # ASCII ctrl chars
    //sgx;
    $str =~ s/\r\n/\n/sg;
    return $str;
}

=item telnet_dump($header, $str)

Simple function used in debuging telnet data

=cut

sub telnet_dump {
    my ($header,$str) = @_;
    print "$header\n";
    for(my $i=0; $i<length($str);$i++) {
        my $char = substr($str, $i, 1);
        print "  ".sprintf("0x%02x(%03d)", ord($char), ord($char))." : "
            .($telnet_codes{$char}{name} or $char)."\n";
    }
}

=back

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2007 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
