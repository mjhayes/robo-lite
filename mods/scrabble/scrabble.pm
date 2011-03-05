# vim: expandtab:ts=4

package mods::scrabble::scrabble;

use strict;
use warnings;

our %hash = ();
our %points = (
        'a' => 1,
        'b' => 3,
        'c' => 3,
        'd' => 2,
        'e' => 1,
        'f' => 4,
        'g' => 2,
        'h' => 4,
        'i' => 1,
        'j' => 8,
        'k' => 5,
        'l' => 1,
        'm' => 3,
        'n' => 1,
        'o' => 1,
        'p' => 3,
        'q' => 10,
        'r' => 1,
        's' => 1,
        't' => 1,
        'u' => 1,
        'v' => 4,
        'w' => 4,
        'x' => 8,
        'y' => 4,
        'z' => 10,
);

sub init {
    open(FH, '<', '/home/matt/robo-lite/mods/scrabble/2of4brif.txt') or return { };
    while (<FH>) {
        chomp;
        $hash{lc($_)} = 1;
    }
    close(FH);

    return {
        command => 'hcommand',
    };
}

sub crap {
    undef &hcommand;
    undef &fcombo;
    undef &cpoints;
    undef &fac;
}

sub hcommand {
    shift;
    my $e = shift;

    if ($e->{data} =~ /^scrabble ([a-zA-Z]{2,8})$/) {
        my %results = ();
        my $lts = lc($1);

        my $len = length($lts);

        print {$e->{sock}} "PRIVMSG ".$e->{dest}.
                           " :Testing (".fac($len).") combinations!\r\n";

        threads->create(sub {
            $SIG{'KILL'} = sub { threads->exit(); };
            for (my $i = 0; $i < $len; $i++) {
                my $head = substr($lts, $i, 1);
                my $tail = substr($lts, 0, $i).substr($lts, $i + 1);
                fcombo($head, $tail, \%results);
            }

            my $nada = 1;
            my $str = "PRIVMSG ".$e->{dest}." :";
            foreach (sort { $results{$b} <=> $results{$a} } keys %results) {
                $nada = 0;

                my $nstr = "(".$_." ".$results{$_}.")";
                if (length($str) + length($nstr) > 400) {
                    print "len: ".length($str)."\n";
                    print "str: ".$str."\n";
                    print {$e->{sock}} $str."\r\n";
                    $str = "PRIVMSG ".$e->{dest}." :".$nstr;
                    sleep(1);
                } else {
                    $str .= $nstr;
                }
            }

            if (length($str) > 0) {
                print {$e->{sock}} $str."\r\n";
            }

            if ($nada) {
                print {$e->{sock}} "PRIVMSG ".$e->{dest}." :No results, nub.\r\n";
            }
        });
    }
}

sub fcombo {
    my ($head, $tail, $res) = @_;

    return if ($tail eq '');

    my $len = length($tail);
    for (my $i = 0; $i < $len; $i++) {
        my $cnc = $head.substr($tail, $i, 1);

        if (defined($hash{$cnc})) {
            $res->{$cnc} = cpoints($cnc);
        }

        fcombo($cnc, substr($tail, 0, $i).substr($tail, $i + 1), $res);
    }
}

sub cpoints {
    my $word = shift;

    my $len = length($word);
    my $t = 0;
    for (my $i = 0; $i < $len; $i++) {
        $t += $points{substr($word, $i, 1)};
    }

    return $t;
}

sub fac {
    my $n = shift;

    return 1 if ($n == 1);
    return $n * fac($n - 1);
}

1;
