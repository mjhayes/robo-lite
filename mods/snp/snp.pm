# vim: expandtab:ts=4

package mods::snp::snp;

use strict;
use warnings;

use Data::Dumper;

# Holds the last thing said.
our %last_said = ();

sub init {
        return { privmsg => 'hprivmsg' };
}

sub crap {
        undef &hprivmsg;
        undef &record_said;
}

sub hprivmsg {
        shift;
        my $e = shift;

        my @data = split(/\s*\&\&\s*/, $e->{data});
        my $did_something = 0;
        my $last = $last_said{$e->{dest}."_DATA"} || "";
        my $ts = $last_said{$e->{dest}."_TIMESTAMP"} || "";

        foreach (@data) {
                # Search and replace trigger.
                if ($_ =~ /^s\/(.+)\/(g)?$/) {
                        eval("\$last =~ s/".$1."/g") if ($2);
                        eval("\$last =~ s/".$1."/") unless ($2);

                        # Remove \r\n to prevent expoits.
                        $last =~ s/[\r\n]//g;

                        if (!$@) {
                                $did_something = 1;
                        }
                }
        }

        print {$e->{sock}} "PRIVMSG ".$e->{dest}." :".$ts.$last."\r\n" if ($did_something);
        record_said($e) unless ($did_something);
}

# Store the last thing said for a specific channel/private message.
sub record_said {
        my $e = shift;

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        $e->{from} =~ /^([^!]+)!.*$/;
        my $nick = $1;

        if ($hour < 10) { $hour = "0".$hour; }
        if ($min < 10) { $min = "0".$min; }

        # Store line as last said.
        if ($e->{data} =~ /^\001ACTION (.+)\001/) {
                $last_said{$e->{dest}."_DATA"} = $1;
                $last_said{$e->{dest}."_TIMESTAMP"} = $hour.":".$min." \002* ".$nick."\002 ";
        } else {
                $last_said{$e->{dest}."_DATA"} = $e->{data};
                $last_said{$e->{dest}."_TIMESTAMP"} = $hour.":".$min." <".$nick."> ";
        }
}

1;
