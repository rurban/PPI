#!/usr/bin/perl

# Unit testing for PPI::Token::HereDoc

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;
	no warnings 'once';
	$PPI::XS_DISABLE = 1;
	$PPI::Lexer::X_TOKENIZER ||= $ENV{X_TOKENIZER};
}
use Test::Deep;
use Test::More;
use Test::NoWarnings;
use PPI;

sub h;

plan tests => 1 + 5;

# List of tests to perform. Each test requires the following information:
#     - 'name': the name of the test in the output.
#     - 'content': the Perl string to parse using PPI.
#     - 'expected': a hashref with the keys being property names on the
#       PPI::Token::HereDoc object, and the values being the expected value of
#       that property after the heredoc block has been parsed.

	# Tests with a carriage return after the termination marker.
h	{
		name     => 'Bareword terminator.',
		content  => "my \$heredoc = <<HERE;\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
		},
	};
h	{
		name     => 'Single-quoted bareword terminator.',
		content  => "my \$heredoc = <<'HERE';\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
		},
	};
h	{
		name     => 'Double-quoted bareword terminator.',
		content  => "my \$heredoc = <<\"HERE\";\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'interpolate',
		},
	};
h	{
		name     => 'Command-quoted terminator.',
		content  => "my \$heredoc = <<`HERE`;\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'command',
		},
	};
h	{
		name     => 'Legacy escaped bareword terminator.',
		content  => "my \$heredoc = <<\\HERE;\nLine 1\nLine 2\nHERE\n",
		expected => {
			_terminator_line => "HERE\n",
			_damaged         => undef,
			_terminator      => 'HERE',
			_mode            => 'literal',
		},
	};

sub h {
    my ( $test ) = @_;
	subtest(
		$test->{name},
		sub {
			plan tests => 6 + keys %{ $test->{expected} };

			my $document = PPI::Document->new( \$test->{content} );
			isa_ok( $document, 'PPI::Document' );

			my $heredocs = $document->find( 'Token::HereDoc' );
			is( ref $heredocs,     'ARRAY', 'Found heredocs.' );
			is( scalar @$heredocs, 1,       'Found 1 heredoc block.' );

			my $heredoc = $heredocs->[0];
			isa_ok( $heredoc, 'PPI::Token::HereDoc' );
			can_ok( $heredoc, 'heredoc' );

			my @content = $heredoc->heredoc;
			is_deeply(
				\@content,
				[ "Line 1\n", "Line 2\n", ],
				'The returned content does not include the heredoc terminator.',
			) or diag "heredoc() returned ", explain \@content;

			is( $heredoc->{$_}, $test->{expected}{$_}, "property '$_'" ) for keys %{ $test->{expected} };
		}
	);
}
