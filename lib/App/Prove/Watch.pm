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
	my ($args, $prove_args) = $class->split_args(@_);
	
	my $watcher      = Filesys::Notify::Simple->new($args->{watch});
	my $handle_alert = $class->_get_notification_sub;
	
	my $last;
	my $prove = sub {
		my $app = App::Prove->new;
		
		$app->process_args(@$prove_args);
		my $ret = $app->run ? 1 : 0;
		
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

sub split_args {
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
