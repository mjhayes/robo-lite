# vim: expandtab:ts=4

package mods::urlparse::urlparse;

use strict;
use warnings;

use HTML::Entities;
use LWP::UserAgent;

sub init {
    return { privmsg => 'hprivmsg' };
}

sub crap {
    undef &hprivmsg;
    undef &read_link;
    undef &calc_size;
}

# PRIVMSG events.
sub hprivmsg {
    shift;
    my $e = shift;

    # URL trigger.
    if ($e->{data} =~ /^\s*(http:\/\/\S+)\s*$/) {
        threads->create(sub {
            $SIG{'KILL'} = sub { threads->exit(); };
            read_link($e, $1);
        });
    }
}

# Read the link's HTML.
sub read_link {
    my ($e, $url) = @_;

    # Download the HTML content.
    # The get() function downloads any text file from the web
    # and will store it in a variable.
    my $ua = LWP::UserAgent->new(
        agent => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.2) '.
                 'Gecko/2008092313 Ubuntu/8.04 (hardy) Firefox/3.1'
    );

    my $response = $ua->head($url);
    if (!$response->is_success) {
        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                           " :Could not download page head!\r\n";
        return;
    }

    # Get the content-type and content-length.
    my $type = $response->header("Content-Type");
    my $length = $response->header("Content-Length");

    # Set the max size of the content we will read in. (10kb)
    $ua->max_size(10240);

    # If this is text/html, we will try to read the title tag.
    if ($type =~ /text\/html/ || $type =~ /application\/xml/) {
        $response = $ua->get($url);
        if (!$response->is_success) {
            print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                               " :Could not download page content!\r\n";
            return;
        }

        my $content = $response->content;
        my $title = "N/A";

        # Remove all line feeds/breaks.
        $content =~ s/[\r\n]//g;

        # Search for <title></title> block.
        $title = $1 if ($content =~ /<title>\s*([^<]+)\s*<\/title>/i);

        # Replace any ascii codes with their corresponding characters.
        decode_entities($title);

        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.' :'.$title.
                           " \002(\002".calc_size($length)."\002)\002\r\n";
    } else {
        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.' :'.$type.
                           " \002(\002".calc_size($length)."\002)\002\r\n";
    }
}

# Return a formatted file size.
sub calc_size {
    my $length = shift;

    return "N/A" unless ($length);

    # M
    if ($length > (1024 * 1024)) {
        $length /= 1024 * 1024;
        return sprintf "%.1f%s", $length, "M";
    # K
    } elsif ($length > 1024) {
        $length /= 1024;
        return sprintf "%.1f%s", $length, "K";
    # B
    } else {
        return sprintf "%.1f%s", $length, "B";
    }
}

1;
