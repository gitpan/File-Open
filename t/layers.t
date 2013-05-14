use warnings;
use strict;

use Test::More tests => 18;

use File::Spec qw(tempfile);
use File::Temp;

use File::Open qw(fopen);

sub slurp {
	my ($fh) = @_;
	local $/;
	scalar readline $fh
}

sub istext ($$) {
	my ($x, $y) = @_;
	@_ = map sprintf('%vx', $_), @_;
	goto &is;
}

my $DIR = File::Temp->newdir('F_O_test.XXXXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
-w $DIR or BAIL_OUT "$DIR: I can't test open() without a writeable temp directory";

sub scratch {
	my ($stem) = @_;
	my $template = File::Spec->catfile($DIR, "$stem.XXXXXX");
	File::Temp::mktemp($template)
}

my $raw_bytes = pack 'H*', '6240C39FE282AC';

my $source = scratch 'enc';
for my $fh (fopen $source, 'wb') {
	print $fh $raw_bytes or die "$source: $!";
	close $fh or die "$source: $!";
}

for my $encoding (':encoding(ISO-8859-1)') {
	{
		my $wanted = slurp do {
			open my $fh, "<", $source or die "$source: $!";
			binmode $fh;
			$fh
		};
		my $got = slurp fopen $source, 'rb';
		istext $got, $wanted;
		istext $got, $raw_bytes;
	}

	{
		my $wanted = slurp do {
			open my $fh, "<$encoding", $source or die "$source: $!";
			$fh
		};
		my $got = slurp fopen $source, 'r', $encoding;
		istext $got, $wanted;
		istext $got, "b\@\xc3\x9f\xe2\x82\xac";
	}
}

{
	use open ':encoding(ISO-8859-11)';

	{
		my $wanted = slurp do {
			open my $fh, "<", $source or die "$source: $!";
			binmode $fh;
			$fh
		};
		my $got = slurp fopen $source, 'rb';
		istext $got, $wanted;
		istext $got, $raw_bytes;
	}

	{
		my $wanted = slurp do {
			open my $fh, "<", $source or die "$source: $!";
			$fh
		};
		my $got = slurp fopen $source;
		istext $got, $wanted;
		istext $got, "b\@\x{e23}\x9f\x{e42}\x82\x{e0c}";
	}

	{
		use open ':encoding(UTF-8)';

		{
			my $wanted = slurp do {
				open my $fh, "<", $source or die "$source: $!";
				binmode $fh;
				$fh
			};
			my $got = slurp fopen $source, 'rb';
			istext $got, $wanted;
			istext $got, $raw_bytes;
		}

		{
			my $wanted = slurp do {
				open my $fh, "<", $source or die "$source: $!";
				$fh
			};
			my $got = slurp fopen $source;
			istext $got, $wanted;
			istext $got, "b\@\xdf\x{20ac}";
		}
	}

	{
		my $wanted = slurp do {
			open my $fh, "<", $source or die "$source: $!";
			$fh
		};
		my $got = slurp fopen $source;
		istext $got, $wanted;
		istext $got, "b\@\x{e23}\x9f\x{e42}\x82\x{e0c}";
	}
}

for my $encoding (':encoding(ISO-8859-1)') {
	{
		my $wanted = slurp do {
			open my $fh, "<", $source or die "$source: $!";
			binmode $fh;
			$fh
		};
		my $got = slurp fopen $source, 'rb';
		istext $got, $wanted;
		istext $got, $raw_bytes;
	}

	{
		my $wanted = slurp do {
			open my $fh, "< $encoding", $source or die "$source: $!";
			$fh
		};
		my $got = slurp fopen $source, 'r', $encoding;
		istext $got, $wanted;
		istext $got, "b\@\xc3\x9f\xe2\x82\xac";
	}
}
