package mods::basic::basic;

use strict;
use warnings;

sub init {
        return {
                ping => 'hping',
                raw => 'hraw',
                privmsg => 'hprivmsg',
                command => 'hcommand',
                help => 'hhelp',
        };
}

sub crap {
        undef &hraw;
        undef &hping;
        undef &hprivmsg;
        undef &hcommand;
        undef &hhelp;
        undef &lsmod;
}

sub hraw {
        shift;
        my $e = shift;

        if ($e->{raw} == 1) {
                my @chans = split(/\s*,\s*/, $e->{sinfo}->{chans});
                foreach (@chans) {
                        print "  Joining $_\n";
                        print {$e->{sock}} 'JOIN '.$_."\r\n";
                }
        } elsif ($e->{raw} == 433) {
                print {$e->{sock}} 'NICK '.$e->{sinfo}->{anick}."\r\n".
                                   'USER '.$e->{sinfo}->{username}.
                                   ' 0 0 :'.$e->{sinfo}->{realname}."\r\n";
                $e->{conns}->{$e->{server}}->{curnick} = $e->{sinfo}->{anick};
        }
}

sub hping {
        shift;
        my $e = shift;

        print {$e->{sock}} 'PONG '.$e->{data}."\r\n";
}

sub hprivmsg {
        shift;
        my $e = shift;

        # CTCP version request.
        if ($e->{data} eq "\1VERSION\1") {
                # Send version reply.
                print {$e->{sock}} 'NOTICE '.$e->{dest}.
                                   " :\1VERSION robo-lite v12".
                                   " - pwnagest b0t in teh w0rld.\1\r\n";
        }
}

sub hcommand {
        shift;
        my $e = shift;

        if ($e->{data} =~ /^source/) {
                print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                                   " :http://github.com/mjhayes/robo-lite\r\n";
        } elsif ($e->{data} =~ /^lsmod/) {
                lsmod($e);
        }
}

sub hhelp {
        shift;
        my $e = shift;

        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                           " :lsmod - List loaded modules\r\n";
}

sub lsmod {
        my $e = shift;

        my $m = ' :';
        foreach (keys(%{$e->{mods}})) {
                $m .= "$_ ";
        }

        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.$m."\r\n";
}

1;
