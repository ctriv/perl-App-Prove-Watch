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
	
	sub new  { return bless {}, shift };
	sub wait {
		my ($self, $code) = @_;
		
		$code->({path => 'somefile'});
	}
}

describe "A prove watcher" => sub {
	it "should be able to instantiate itself." => sub {
		my $sut = App::Prove::Watch->new();
		isa_ok($sut, 'App::Prove::Watch');
	};
	
	describe "with a work dir" => sub {
		my $mock = Test::Mock::Simple->new(module => 'App::Prove::Watch');
		$mock->add(watcher  => sub {
			return mock::watcher->new;
		}); 
		
		it "should run tests when files changes" => sub {
			my $ran;
			my $sut = App::Prove::Watch->new(
				'--run' => sub { pass("Called") }
			);
			
			$sut->run(1);
			
		};
	}
};




runtests;