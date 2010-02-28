package mods::genpass::genpass;

use strict;
use warnings;

sub init {
        return { command => 'hcommand' };
}

sub crap {
        undef &hcommand;
        undef &genpass;
}

sub hcommand {
        shift;
        my $e = shift;

        if ($e->{data} =~ /^gen (.+)$/) {
                genpass($e, $1);
        }
}

sub genpass {
        my ($e, $num) = @_;

        my $rval;
        my $i;
        my $out = "";

        if ($num <= 0 || $num > 64) {
                print {$e->{sock}} "PRIVMSG ".$e->{dest}." :\002gen\002: ".
                                   "use a value between 1 and 64 douchebag.\r\n";
                return;
        }

        for ($i = 0; $i < $num; $i++) {
                $rval = int(rand(95)) + 33;
                $out .= chr($rval);
        }

        $e->{from} =~ /(.+)!.+/;
        print {$e->{sock}} "NOTICE ".$1." :\002gen\002: ".$out."\r\n";
}

1;
