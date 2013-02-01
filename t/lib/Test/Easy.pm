use strict;
use warnings;
package Test::Easy;

use Cwd ();

our @EXPORT_OK = qw(deep_ok);  # things the real Test::Easy provides
our @EXPORT = qw(subtest);     # things this Test::Easy provides as a shim

sub import {
	my $class = shift;
	my $caller = caller;

	my ($found) =
		grep { -e $_ && $_ !~ m{^\.} }
		map { "$_/Test/Easy.pm" }
		@INC;

	if ($found && Cwd::abs_path($found) ne Cwd::abs_path(__FILE__)) {
		local $@;
		eval "package $caller; do '$found'";
		die $@ if $@; # I haven't actually tested this branch yet
  } else {
		no strict 'refs';
		no warnings 'redefine';
		my %exportable = map { $_ => 1 } @EXPORT_OK;
		foreach (@EXPORT, grep { $exportable{$_} } @_) {
			*{"$caller\::$_"} =*{$_}{CODE};
		}
	}
}

sub deep_ok {
	require Data::Dumper;
	Test::More::is_deeply(@_) || Test::More::diag Data::Dumper::Dumper(@_[0,1]);
}

{
	my %subtest_warning_already_shown;
	sub subtest {
		no strict 'refs';
		no warnings 'redefine';
		if (*{'Test::More::subtest'}{CODE}) {
			*subtest = \&Test::More::subtest;
			goto &subtest;
		} else {
			my $name = shift;
			my $test = pop;
			my $caller = caller;
			Test::More::diag <<UH_OH unless $subtest_warning_already_shown{$caller}++;

Uh-oh, it looks like the test you're running uses
'subtest', but your version of Test::More doesn't actually
support subtest. I'm faking out a 'subtest' for you.
Please just make sure the tests pass - don't worry about
failures that are solely related to test counts.
UH_OH
			Test::More::diag <<RUNNING;

Running $name...
RUNNING
			local *{"$caller\::plan"} = sub {};
			$test->();
		}
	}
}

1;

__END__

=head1 NAME

Test::Easy - a shim between Test::Easy elsewhere on the system, and what you've got

=head1 DESCRIPTION

I like good tests. I also like clean production code.

Test suites that impose installing libraries alongside production code are a special
maelstrom of values for me: on the one hand, a good test suite provides a lot of
flexibility and information; on the other, flexibility and information come at the
expense of needing to install additional CPAN libraries.

So this is my compromise. If you've got Test::Easy installed, this module will go find
it and happily delegate to the real Test::Easy.

On the other hand, if you don't have Test::Easy installed, this module will provide
a small amount of adaptation between what you don't have and what you do have.

=head1 COPYRIGHT AND LICENSE

    (c) 2013 by Belden Lyman

This library is free software: you may redistribute it and/or modify it under the same terms as Perl
itself; either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have
available.

