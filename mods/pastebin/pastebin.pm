# vim: expandtab:ts=4

package mods::pastebin::pastebin;

use strict;
use warnings;

use MIME::Base64 ();

sub init {
    return {
        listener => 'hlistener',
        command => 'hcommand',
    };
}

sub crap {
    undef &hlistener;
    undef &hcommand;
}

sub hlistener {
    shift;
    my $e = shift;

    # pb <title>:<poster ip>:<type>:<url>:<size in bytes>
    if (!($e->{data} =~ /^pb ([^:]+):([^:]+):([^:]+):([^:]+):([^:]+)/)) {
        return;
    }

    my $title = MIME::Base64::decode($1);
    my $ip = MIME::Base64::decode($2);
    my $type = MIME::Base64::decode($3);
    my $url = MIME::Base64::decode($4);
    my $size = MIME::Base64::decode($5);
    my $chan;

    if ($e->{server} eq 'thegentlemens') {
        $chan = '#test';
    } elsif ($e->{server} eq 'freenode') {
        $chan = '#nxc';
    } else {
        return;
    }

    print {$e->{sock}} "PRIVMSG $chan :pb: ".
                       '"'.$title.'" '.
                       "($type: $size bytes) ".
                       "by $ip - $url".
                       "\r\n";
}

sub hcommand {
    shift;
    my $e = shift;

    if ($e->{data} =~ /^(pb|paste|pastebin)$/) {
        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                           " :http://nxc.mooo.com/pb\r\n";
    }
}

1;
