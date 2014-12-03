package App::Prove::Watch;


use strict;
use warnings;

use App::Prove;
use Filesys::Notify::Simple;
use File::Basename;
use Getopt::Long qw(GetOptionsFromArray);


=head1 NAME

App::Prove::Watch - Run tests whenever changes occur.

=cut

sub run {
	my $class = shift;
	my ($args, $prove_args) = $class->_split_args(@_);
	
	my $watcher      = Filesys::Notify::Simple->new($args->{watch});
	my $prove        = $class->_get_prove_sub($args, $prove_args);

	$prove->();

	while (1) {
		$watcher->wait(sub {
			my $doit;
			foreach my $event (@_) {
				my $file = basename($event->{path});
				next if $file =~ m/^(?:\.~)/;
				
				$doit++;
				
			}
			
			if ($doit) {
				$prove->();
			}
		});
	}
}


sub _split_args {
	my ($class, @args) = @_;
	
	my (@ours, @theirs);
	
	while (@args) {
		local $_ = shift @args;
		if ($_ eq '--watch' || $_ eq '--run') {
			push(@ours, $_, shift @args);
		}
		else {
			push(@theirs, $_);
		}
	}
	
	my %ours;
	GetOptionsFromArray(\@ours, \%ours,
		'watch=s@',
		'run=s',
	);
	
	if (!$ours{watch} || !@{$ours{watch}}) {
		$ours{watch} = ['.']
	}	
	
	return (\%ours, \@theirs);
}

sub _get_prove_sub {
	my ($class, $args, $prove_args) = @_;
	
	my $handle_alert = $class->_get_notification_sub;
	
	my $last;
	my $prove;
	
	if ($args->{run}) {
		$prove = sub {
			my $ret = system($args->{run});
			
			return $ret == 0 ? 1 : 0;
		};
	}
	else {
		$prove = sub {
			my $app = App::Prove->new;
			
			$app->process_args(@$prove_args);
			
			return $app->run ? 1 : 0;
		};
	}
	
	return sub {
		my $ret = $prove->();
		
		if (defined $last && $ret != $last) {
			my $msg;
			if ($ret) {
				$msg = "Tests are now passing.";
			}
			else {
				$msg = "Tests are now failing.";
			}
			
			$handle_alert->($msg);
		}
		$last = $ret;
		
		return $ret;
	};
}


sub _get_notification_sub {
	my $has_desk_note = eval {
		require Log::Dispatch::DesktopNotification;
	};
	
	if ($has_desk_note) {
		my $notify = Log::Dispatch::DesktopNotification->new(
			name      => 'notify',
			min_level => 'notice',
			app_name  => 'provewatcher',
		);
		
		return sub {
			$notify->log(
				level   => 'notice',
				message => shift,
			);
		}
	}
	else {
		return sub {};
	}
}
	

1;
