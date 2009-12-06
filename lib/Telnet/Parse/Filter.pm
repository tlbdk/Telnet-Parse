package Telnet::Parse::Filter;
use strict;
use warnings;
use Carp;

use Telnet::Parse qw(telnet_decode);

our $VERSION = '1.00';

=head1 NAME

Telnet::Parse - A module to parse telnet data and options

=head1 DESCRIPTION

This module is used for filtering Telnet text data, and works like much like 
Net::Telnet::Wrapper, except that it only works with data and does not handle
socket creation.  

=head1 SYNOPSIS
  use Telnet::Parse::Filter;

  my $filter = new Telnet::Parse::Filter(
    Prompt => 'auto', # Auto detect prompt type
    Auths => [ { login => 'mylogin', password => 'mypassword'} ]
    Cmds => ['pwd', 'ls -la'],
  );

  # TODO: Provide a working example
  while(1) {
    my $answer = $filter->data($sock->read());
    $sock->send($answer) if $answer;
  }

  if(!$filter->error()) {
    # This will only print the result of the two commands
    foreach my $result ($filter->results()) {
      print "result: "$result";\n";
    }
    # Print extra information gather 
    print $filter->extra('lastlogin');
  } else {
    die "Got error".join(",", $filter->error());
  }

=cut

use base "Exporter";

our @EXPORT = qw();
our @EXPORT_OK = qw();

our %EXPORT_TAGS = (
    ALL => [@EXPORT_OK, @EXPORT],
);

=head1 METHODS

=head2 B<new(%options)>

Constructs a new Telnet::Parse::Filter object

=head3 Cmds

Cmds provides a list of commands that will be run when login has succeeded and
a prompt is returned in the telnet session. Commands will be run in the order
provided and will also be returned in results the same way. Each command will
only be called after a new prompt has been detected

  my $filter = new Telnet::Parse::Filter(
    Cmds => ['pwd', 'ls -la'],
  );

=cut

sub new {
    my ($class, %opts) = @_;
  
    # Check that we are only called with known options
    my %options = map { $_ => 1 } qw(Prompt Auths Cmds Scanning); 
    map { croak "Unknown option: $_" if !exists $options{$_} }
        keys %opts;

    croak "Option Prompt should be 'auto' or a regexp" if $opts{Prompt} and !( 
        (ref $opts{Prompt} eq '' and $opts{Prompt} eq 'auto') or
        (ref $opts{Prompt} eq 'Regexp'));
    
    croak "Option Auths should be an array ref" if $opts{Auths} and !(
        ref $opts{Auths} eq 'ARRAY');

    croak "Option Cmds should be an array ref" if $opts{Cmds} and !(
        ref $opts{Cmds} eq 'ARRAY');
   
    # Set default auth type to 'auto' if it's not set
    foreach my $auth (@{$opts{Auths}}) {
        if(exists $auth->{login} and !exists $auth->{password}) {
            $auth->{type} = 'unknown' if !exists $_->{type};

        } elsif(exists $auth->{password}) {
            $auth->{type} = 'auto' if !exists $_->{type};
        
        } else {
            $auth->{type} = 'unknown' if !exists $_->{type};
        }
        $auth->{type} = 'auto' if !exists $_->{type};
    }

    my %self = (
        prompts => ref $opts{Prompt} eq 'Regexp' ? [$opts{Prompt}] : [
            qr/(\n)?\[.+?[\~\w\d]+\]\$/,
            qr/[\~\d\w]+\]\$/, 
            qr/(?m:^[\r\w.-]+\s?(?:\(config[^\)]*\))?\s?[\$#>]\s?(?:\(enable\))?\s*$)/,
            qr/\n\$/,
        ],
        auths    => ($opts{Auths} or []),
        cmds     => ($opts{Cmds} or []), 
        scanning => $opts{Scanning},
        type     => '', # Holds detected type, eg. "Linux", etc
        'last'   => '', # Holds that last "state" we entered
        prompt   => '', # Holds the prompt regexp that worked
        extras   => {}, # Holds extra information gather under the login process
        results  => [], # Holds our command results
        error    => '', # Holds our error
        done     => 0,
    );
   
    return bless \%self, (ref $class || $class);
}

# TODO: Cleanup API

sub done {
    my($self, $done) = @_;
    $self->{done} = $done if defined $done;
    return $self->{done};
}

sub type {
    my($self, $type) = @_;
    $self->{type} = $type if defined $type;
    return $self->{type};
}

sub last {
    my($self, $last) = @_;
    $self->{last} = $last if defined $last;
    return $self->{last};
}

sub cmds {
    my($self, @cmds) = @_;
    $self->{cmds} = \@cmds if @cmds;
    return @{$self->{cmds}};
}

sub prompt {
    my($self, $prompt) = @_;
    $self->{prompt} = $prompt if defined $prompt;
    return $self->{prompt};
}

sub auth {
    my($self) = @_;
    
    my $auth = {
        (defined $self->{auth}{login} ? 
            (login => $self->{auth}{login}) : ()), 
        (defined $self->{auth}{password} ? 
            (password => $self->{auth}{password}) : ()), 
        (defined $self->{auth}{enable} ? 
            (enable => $self->{auth}{enable}) : ()),
    };
    
    return $auth;
}

sub auths {
    my($self, $auths) = @_;
    $self->{auths} = $auths if defined $auths;
    return [($self->{auth} or ()), @{$self->{auths}}];
}

sub next_auth {
    my($self) = @_;
    $self->{auth} = shift @{$self->{auths}};
}

sub reset {
    my($self) = @_;
    $self->last("");
    $self->{text} = '';
}

sub auth_type {
    my($self) = @_;
    return $self->{auth_type};
}

sub error {
    my($self, $clear) = @_;
    my $error = $self->{error};
    $self->{error} = '' if defined $clear;
    return $error;
}

sub results {
    my($self, $clear) = @_;
    my @results = @{$self->{results}};
    $self->{results} = [] if defined $clear;
    return @results;
}

sub extras {
    my($self, $key) = @_;
    return $self->{extras}{$key};
}

sub data {
    my($self, $str) = @_;
    my $answer;
    
    # Add next data part to the buffer
    $self->{text} .= $str;

    # Remove all ESC chars and other cruff so regexp is easier, but don't do 
    # it for the real string as we might only have gotten half of the ESC chars
    $str = telnet_decode($self->{text}); 

    my $last = 'unchanged';
    my $count = 0;
    while($last ne $self->{last} and length $self->{text} and $count++<5) {
        $last = $self->{last};
        #print "($last): '$str'\n"; 
        
        # '' state
        if($self->{last} eq '') {
            # Linux 2.6.24-rc3 (localhost.localdomain) (5)
            if($str =~ /Linux\s*([a-z\d\-\.]+)?\s*/si) {
                $self->{type} = 'Linux';
                $self->{extras}{kernelversion} = $1 if defined $1;
            
            # User Access Verification 
            } elsif($str =~ /User Access Verification/si) {
                $self->{type} = 'Cisco::IOS';
            
            # Cisco Systems, Inc. Console
            } elsif($str =~ /Cisco Systems, Inc. Console/si) {
                $self->{type} = 'Cisco::IOS';
            }
       

            # Support Cisco login prompt and other where no $login is required
            if($str =~ /(?:Password:)|(?:Enter password)/si) {
                # Only keep the correct login type
                @{$self->{auths}} = grep { !defined $_->{login} } 
                    @{$self->{auths}} if !exists $self->{auth_type};
                $self->{auth_type} = 'password';
                $self->{auth} = shift @{$self->{auths}} if !$self->{auth};
                
                # Set done if we are in scanning mode
                if ($self->{scanning}) {
                    $self->{done} = 1;
                    last;
                }
                
                $self->{last} = 'login';

            } elsif($str =~ /(login|Username|User):/si) {
              
                # Only keep the correct login type
                @{$self->{auths}} = grep { defined $_->{login} } 
                    @{$self->{auths}} if !exists $self->{auth_type};
                $self->{auth_type} = 'login';
                $self->{auth} = shift @{$self->{auths}} if !$self->{auth};

                # Set type if we did not detect it with the banner
                if($self->{type} eq 'auto') {
                    if($1 eq 'Username') {
                        $self->{type} = 'Cisco::IOS';
                    } elsif($1 eq 'login') {
                        $self->{type} = 'Linux';
                    }
                }
              
                # Set done if we are in scanning mode
                if ($self->{scanning}) {
                    $self->{done} = 1;
                    last;
                }

                $self->{text} = '';
                $self->{last} = 'login';
                
                if(my $auth = $self->{auth}) {
                    $answer .= "$auth->{login}\r\n";
                
                } else {
                    $self->{error} = "No more logins to try";
                }
                last;
            } else {
                # Try to find the correct prompt as some boxes will not ask 
                # for password
                foreach my $prompt (@{$self->{prompts}}) {
                    #print "$prompt, ($self->{text})\n"; 
                    # [hk@tlbc ~]$
                    if($str =~ /$prompt/s) {
                        $self->{text} = '';
                        $self->{result} = '';
                        $self->{last} = 'prompt';
                        $self->{prompt} = $prompt;
                        $self->{auth} = shift @{$self->{auths}};
                        
                        # Remove unused login and password
                        delete $self->{auth}{login}; 
                        delete $self->{auth}{password}; 

                        # Get the next command 
                        if(my $cmd = shift(@{$self->{cmds}})) {
                            $answer .= "$cmd\r\n";
                            $self->{cmd} = $cmd;
                        } else {
                            $self->{done} = 1;
                        }
                        last;
                    }
                }
            }
   
        # 'password' state
        } elsif($self->{last} eq 'login') {
            if($str =~ /Login incorrect/si) {
                $self->{last} = '';
                $self->{auth} = shift @{$self->{auths}};
             
            } elsif($str =~ /Authentication failed/si) {
                $self->{last} = '';
                $self->{auth} = shift @{$self->{auths}};

            } elsif($str =~ /(Password|Enter PASSCODE):/si) {
                # Set type if we did not detect it with the banner
                if($self->{type} eq 'auto') {
                    if($1 eq 'Enter PASSCODE') {
                        $self->{type} = 'Cisco::IOS';
                    }
                }
                
                # Clear text and set state
                $self->{text} = '';
                $self->{last} = 'password';
               
                # Set answer or push error
                if(my $auth = $self->{auth}) {
                    $answer .= $auth->{password}."\r\n";
                
                } else {
                    $self->{error} = "No more logins to try";
                }
                last;
            } 
   
        # 'prompt' state
        } elsif($self->{last} eq 'password') {
            
            if($str =~ /User:|Login incorrect/si) {
                $self->{last} = '';
                $self->{auth} = shift @{$self->{auths}};
            
            } elsif($str =~ /Invalid username or password/si) {
                $self->{last} = '';
                $self->{auth} = shift @{$self->{auths}};
            
            } elsif($str =~ /Password:/si) {
                $self->{last} = 'login';
                $self->{auth} = shift @{$self->{auths}};
            
            } elsif($self->{text} =~ /Bad passwords/si) {
                $self->{text} = '';
                $self->{last} = '';
                $self->{auth} = shift @{$self->{auths}};
            
            } elsif($self->{text} =~ /Maximum number of tries exceeded/si) {
                $self->{text} = '';
                $self->{last} = '';
                #$self->{auth} = shift @{$self->{auths}};
            
            } elsif($str =~ /Authentication failed|Failed login/si) {
                $self->{auth} = shift @{$self->{auths}};
                $self->{last} = '';
            }

            # Last login: Sat Nov 17 23:35:40 WET 2007 from 
            if($self->{text} =~ /Last login:\s*(?:(.+)\s+from)?/si) {
                $self->{extras}{lastlogin} = $1 if defined $1;
            }
       
            # Try to find the correct prompt
            foreach my $prompt (@{$self->{prompts}}) {
                #print "$prompt, ($self->{text})\n"; 
                # [hk@tlbc ~]$
                if($str =~ /$prompt/s) {
                    $self->{text} = '';
                    $self->{result} = '';
                    $self->{last} = 'prompt';
                    $self->{prompt} = $prompt;
            
                    # Get the next command 
                    if(my $cmd = shift(@{$self->{cmds}})) {
                        $answer .= "$cmd\r\n";
                        $self->{cmd} = $cmd;
                    } else {
                        $self->{done} = 1;
                    }
                    last;
                }
            }

        # 'cmd' state
        } elsif($self->{last} eq 'prompt') {
            # FIXME: Does not support connection lose, ie. max 3 enable passwords
            # Support Cisco enable passwords
            #
            if($str =~ /^\s*(?:Sorry|% Access denied|Failed login)(.*)$self->{prompt}/si) {
                $answer .= "en\r\n";
                $self->{text} = '';

            } elsif($str =~ /(Password):/si) {
                if(!exists $self->{auth}{used}) {
                    if($self->{auth}{enable}) {
                        $answer .= "$self->{auth}{enable}\r\n";
                        $self->{auth}{used} = 1;

                    } else {
                        $self->{auth} = shift @{$self->{auths}};
                        die "RECONNECT: Enable password did not match";
                    }
                    $self->{text} = '';
                
                } else {
                    $self->{auth} = shift @{$self->{auths}};
                    die "RECONNECT: No more logins to try under enable";
                }
                last;
            
            # Support cisco paging
            } elsif($str =~ /\n--More--/si) {
                $answer .= " ";
                $self->{text} =~ s/--More--//si; # Remove --More-- from output
                $str =~ s/--More--//si; # Remove --More-- from output
            
            } elsif($str =~ /\n<-+\s+More\s+-+>/si) {
                $answer .= " ";
                $self->{text} =~ s/<-+\s+More\s+-+>//si; # Remove --More-- from output
                $str =~ s/<-+\s+More\s+-+>//si; # Remove --More-- from output
            
            # Match the prompt
            } elsif($str =~ /^(.*)$self->{prompt}/si) {
                $self->{result} .= $1 if defined $1;
            
                $self->{text} = '';
                $self->{last} = 'prompt';

                # Remove echoed command and lineendings from start and end 
                $self->{result} =~ s/^\n?(?:$self->{cmd})?\n?//s;
                $self->{result} =~ s/\n$//s;
        
                push(@{$self->{results}}, $self->{result});
                $self->{result} = '';

                # Get the next command 
                if(my $cmd = shift(@{$self->{cmds}})) {
                    $answer .= "$cmd\r\n";
                    $self->{cmd} = $cmd;
                } else {
                    $self->{done} = 1;
                }
                last;
            }
        }
    }

    return $answer;
}

1;

