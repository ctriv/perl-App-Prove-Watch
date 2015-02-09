# -*- perl -*-


use Test::More;
use Test::Spec;
use File::Touch;
use File::Temp qw/tempdir/; 
use File::Spec;
use App::Prove::Watch;
use Test::Mock::Simple;

{
	package mock::watcher;
	use strict;
	use warnings;
	
	sub new  {
		my $class = shift;
		return bless [@_], $class;
	}
	
	sub wait {
		my ($self, $code) = @_;
		
		# not right yet
		my $path = shift @$self;
		warn "# path - $path ($self)\n";
		$code->({ path => $path });
	}
}

describe "A prove watcher" => sub {
	it "should be able to instantiate itself." => sub {
		my $sut = App::Prove::Watch->new();
		isa_ok($sut, 'App::Prove::Watch');
	};
	
	xdescribe "with a work dir" => sub {
		my $mock = Test::Mock::Simple->new(module => 'App::Prove::Watch');
		
		$mock->add(watcher  => sub {
			return mock::watcher->new('somefile');
		}); 
		
		it "should run tests when files changes" => sub {
			my $sut = App::Prove::Watch->new(
				'--run' => sub { pass("Called") }
			);
			
			$sut->run(1);	
		};
	};
	
	xdescribe "with ignore arguments" => sub {
		my $mock = Test::Mock::Simple->new(module => 'App::Prove::Watch');
		$mock->add(watcher  => sub {
			return mock::watcher->new(qw/somefile anotherfile/);
		}); 
		
		it "should ignore files it was told to ignore" => sub {
			my $called = 0;
			my $sut = App::Prove::Watch->new(
				'--run'    => sub { $called++ },
				'--ignore' => 'some.*'
			);
			
			$sut->run(1);
			
			is($called, 2);
		};	
	};
};




runtests;