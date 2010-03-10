package mods::genpass::genpass;

use strict;
use warnings;

sub init {
        return {
                command => 'hcommand',
                help => 'hhelp',
        };
}

sub crap {
        undef &hcommand;
        undef &hhelp;
        undef &genpass;
}

sub hcommand {
        shift;
        my $e = shift;

        if ($e->{data} =~ /^gen (.+)$/) {
                genpass($e, $1);
        }
}

sub hhelp {
        shift;
        my $e = shift;

        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                           " :gen [1-64] - Generate a random string\r\n";
}

sub genpass {
        my ($e, $num) = @_;

        my $rval;
        my $i;
        my $out = "";

        if ($num <= 0 || $num > 64) {
                print {$e->{sock}} 'PRIVMSG '.$e->{dest}.' :'.
                                   "use a value between 1 and 64 douchebag.\r\n";
                return;
        }

        for ($i = 0; $i < $num; $i++) {
                $rval = int(rand(95)) + 33;
                $out .= chr($rval);
        }

        $e->{from} =~ /(.+)!.+/;
        print {$e->{sock}} "NOTICE ".$1.' :'.$out."\r\n";
}

1;
