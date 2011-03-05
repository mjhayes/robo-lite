# vim: expandtab:ts=4

package mods::weather::weather;

use strict;
use warnings;

use XML::Simple;
use LWP::Simple;

sub init {
    return {
        command => 'hcommand',
        help => 'hhelp',
    };
}

sub crap {
    undef &hcommand;
    undef &hhelp;
    undef &read_weather;
}

sub hcommand {
    shift;
    my $e = shift;

    if ($e->{data} =~ /^weather (.+)$/) {
        threads->create(sub {
            $SIG{'KILL'} = sub { threads->exit(); };
            read_weather($e, $1);
        });
    }
}

sub hhelp {
    shift;
    my $e = shift;

    print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                       " :weather [zip|city] - Show current forecast info\r\n";
}

# Read the Google weather XML feed.
sub read_weather {
    my ($e, $input) = @_;

    # Download the xml content:
    # The get() function downloads any text file from the web
    # and will store it in a variable.
    my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0 (X11; U; Linux i686; '.
                                          'en-US; rv:1.9.0.2) '.
                                          'Gecko/2008092313 Ubuntu/8.04 '.
                                          '(hardy) Firefox/3.1');

    my $response = $ua->get("http://www.google.com/ig/api?weather=".$input);
    if (!$response->is_success) {
        print {$e->{sock}} 'PRIVMSG '.$e->{dest}.
                           " :Could not download weather XML!\r\n";
        return;
    }

    my $content = $response->content;

    # Open the XML feed.
    my $xml = XMLin($content) or return;

    my $city = $xml->{weather}->{forecast_information}->{city}->{data};
    my $cur_temp = $xml->{weather}->{current_conditions}->{temp_f}->{data};
    my $cur_wind = $xml->{weather}->{current_conditions}->{wind_condition}->{data};
    my $cur_skies = $xml->{weather}->{current_conditions}->{condition}->{data};
    my $high = $xml->{weather}->{forecast_conditions}->[0]->{high}->{data};
    my $low = $xml->{weather}->{forecast_conditions}->[0]->{low}->{data};
    my $condition = $xml->{weather}->{forecast_conditions}->[0]->{condition}->{data};

    print {$e->{sock}} 'PRIVMSG '.$e->{dest}.' :'.$city.
                       ' - Current temp: '.$cur_temp.'F - '.$cur_wind.
                       ' - High: '.$high.' - Low: '.$low.
                       ' - Condition: '.$condition."\r\n";
}

1;
