#!/usr/bin/perl -w
use strict;
my $overlay = shift;

while(<>) {
	last if m{</svg>};
	print;
}

open(my $ovlfd, "<", $overlay) or die "cannot find overlay SVG '$overlay': $!";
my $print;
my @ovl=();
my $line;
while(<$ovlfd>) {
	if(m{<path}) {$print=1}
	if(m{</g>}) {$print=0}
	s/inkscape:connector-curvature="0"//;
	chomp;
	if($print) {
		$line .= $_;
		if(m{/>}) { push(@ovl, $line); $line="" }
	}
}
close $ovlfd;

my $dx=-7.0;
my $dy=7.0;
my $scale=0.099;
print qq'<g transform="translate($dx,$dy)"><g transform="scale($scale)" style="opacity:0.7">', join "\n", @ovl, "</g></g>";

print "</svg>\n";
