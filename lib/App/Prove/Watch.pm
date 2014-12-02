package App::Prove::Watch;

use strict;
use warnings;

use App::Prove;
use Filesys::Notify::Simple;
use File::Basename;

=head1 NAME

App::Prove::Watch - Run tests whenever changes occur.

=cut


sub run {
	my ($class, @args) = @_;
	
	my $watcher = Filesys::Notify::Simple->new(["."]);
	
	my $has_desk_note = eval {
		require Log::Dispatch::DesktopNotification;
	};
	
	my $handle_alert = sub {};
	
	if ($has_desk_note) {
		my $notify = Log::Dispatch::DesktopNotification->new(
			name      => 'notify',
			min_level => 'notice',
			app_name  => 'provewatcher',
		);
		
		$handle_alert = sub {
			$notify->log(
				level   => 'notice',
				message => shift,
			);
		}
	}
	
	my $last;
	my $prove = sub {
		my $app = App::Prove->new;
		
		$app->process_args(@args);
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

1;
