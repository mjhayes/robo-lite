package mods::eval::eval;

use strict;
use warnings;

use Safe;
use threads('yield', 'exit' => 'threads_only');

sub init {
        return { command => 'hcommand' };
}

sub crap {
        undef &hcommand;
        undef &eval_thread;
        undef &eval_timeout;
}

sub hcommand {
        shift;
        my $e = shift;

        # Eval trigger.
        if ($e->{data} =~ /^eval (.+)/) {
                my $thread_eval = threads->create('eval_thread', $e, $1);
                my $thread_timeout = threads->create('eval_timeout', $e, $thread_eval, 2);

                my @ret = $thread_eval->join();
                $thread_timeout->detach();
        }
}

# Performs the safe evaluation.
sub eval_thread {
        my ($e, $one) = @_;

        # Create safe compartment.
        my $compartment = new Safe;
        $compartment->permit_only(
                qw(join rand pushre regcmaybe regcreset regcomp subst substcont concat padany :base_core :base_loop)
        );

        # Thread 'cancellation' signal handler
        $SIG{'KILL'} = sub {
                threads->exit() if threads->can('exit');
                exit(0);
        };

        # Evaluate the expression.
        my $result = $compartment->reval($one);
        $result = $@ if $@;

        # No result.
        if (!defined($result)) {
                print {$e->{sock}} "PRIVMSG ".$e->{dest}." :eval: No result returned!\r\n";
                return;
        }

        # Results sometimes have multiple lines, so split it.
        my @results = split(/\n/, $result);

        # Print out each line of the results.
        foreach (@results) {
                print {$e->{sock}} "PRIVMSG ".$e->{dest}." :eval: ".$_."\r\n";
                sleep(1);
        }
}

# Kills the eval thread if it runs for too long.
sub eval_timeout {
        my ($e, $thread, $timeout) = @_;

        # This determines how long we let our eval thread run for.
        sleep($timeout);

        # If the thread is still running, stop it.
        if ($thread && $thread->is_running()) {
                print {$e->{sock}} "PRIVMSG ".$e->{dest}.
                      " :eval: Evaluation terminated (exceeded alotted time of ".
                      $timeout." seconds).\r\n";
                $thread->kill('KILL')->detach();
        }
}

1;
