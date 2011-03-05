# vim: expandtab:ts=4

package mods::bombz::bombz;

use strict;
use warnings;

use LWP::Simple;

sub init {
    return { command => 'hcommand' };
}

sub crap {
    undef &get_bombzcount;
    undef &hcommand;
}

sub hcommand {
    shift;
    my $e = shift;

    if ($e->{data} =~ /^bombz$/) {
        threads->create(sub {
            $SIG{'KILL'} = sub { threads->exit(); };
            get_bombzcount($e);
        });
    }
}

# Get the bombz download count.
sub get_bombzcount
{
    my $e = shift;

    # Retrieve google projects page count
    my $content = get("http://code.google.com/p/bombz-gtk/downloads/list");
    $content =~ s/[\n\r]//g;
    $content =~ s/\s{2,}//g;

    my @filez = ();

    while ($content =~ m/<td class=\"vt id col_0\">\s*<a href=\"(\S+)\".*?>\s*([\w\.\!\-\+]+)\s*<\/a>/g) {
        push(@filez, [$1, $2, 0]);
    }

    my $count = 0;
    while ($content =~ m/<td class=\"vt col_4\".*?>\s*<a onclick=\"cancelBubble=true;\" href=\"(\S+)\".*?>\s*(\d+)\s*<\/a>/g) {
        $filez[$count++]->[2] = $2;
    }

    foreach (@filez) {
        print {$e->{sock}} "PRIVMSG ".$e->{dest}." :".$_->[1]." (".$_->[0].") \002".$_->[2]." downloads\002\r\n";
        sleep(1);
    }

    # Retrieve AUR count
    $content = get("http://aur.archlinux.org/packages.php?ID=21082");
    $content =~ s/[\n\r]//g;
    $content =~ s/\s{2,}//g;

    $content =~ /<span class='f3'>Votes: (\d+)<\/span>/;
    print {$e->{sock}} "PRIVMSG ".$e->{dest}." :AUR: \002".$1." votes\002\r\n";
}

1;
