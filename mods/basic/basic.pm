package mods::basic::basic;

use strict;
use warnings;

sub init {
        return {
                ping => 'hping',
                raw => 'hraw',
                privmsg => 'hprivmsg',
        };
}

sub crap {
        undef &hraw;
        undef &hping;
        undef &hprivmsg;
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

1;
