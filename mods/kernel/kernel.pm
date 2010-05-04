# vim: expandtab:ts=4

package mods::kernel::kernel;

use strict;
use warnings;

use LWP::Simple;
use XML::RSS;

sub init {
        return { command => 'hcommand' };
}

sub crap {
        undef &read_kernel;
        undef &hcommand;
}

sub hcommand {
        shift;
        my $e = shift;

        if ($e->{data} =~ /^kernel$/) {
                read_kernel($e);
        }
}

# Read the kernel.org RSS feed. Word.
sub read_kernel {
        my $e = shift;

        # Download the rss content:
        # The get() function downloads any text file from the web
        # and will store it in a variable. Incredible.
        my $content = get("http://kernel.org/kdist/rss.xml");

        # Parse the RSS feed
        my $rss = new XML::RSS;
        $rss->parse($content);

        my $got26 = 0;
        my $got24 = 0;

        foreach my $item (@{$rss->{items}}) {
                if ((!$got26 && $item->{'title'} =~ /^(2\.6)\.(\d+\.?\d*)\: stable$/) ||
                    (!$got24 && $item->{'title'} =~ /^(2\.4)\.(\d+\.?\d*)\: stable$/)) {
                        $got26 = 1 if ($1 eq "2.6");
                        $got24 = 1 if ($1 eq "2.4");

                        print {$e->{sock}} "PRIVMSG ".$e->{dest}." :\002$item->{'title'}\002\r\n";
                        sleep(1);

                        print {$e->{sock}} "PRIVMSG ".$e->{dest}." :  \002(\002Link\002)\002 http://www.kernel.org/pub/linux/kernel/v$1/linux-$1.$2.tar.bz2\r\n";
                        sleep(1);

                        print {$e->{sock}} "PRIVMSG ".$e->{dest}." :  \002(\002Changelog\002)\002 http://www.kernel.org/pub/linux/kernel/v$1/ChangeLog-$1.$2\r\n";
                } elsif ($item->{'title'} =~ /mainline/) {
                        print {$e->{sock}} "PRIVMSG ".$e->{dest}." :\002$item->{'title'}\002\r\n";
                }
        }
}

1;
