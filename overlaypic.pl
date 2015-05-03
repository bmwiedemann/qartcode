#!/usr/bin/perl -w
use strict;
my $overlay = shift;
my $basepic = "";
while(<>) {
	last if m{</svg>};
	$basepic .= $_;
}

open(my $ovlfd, "<", $overlay) or die "cannot find overlay SVG '$overlay': $!";
my $print;
my @ovl=();
my $line;
while(<$ovlfd>) {
	if(m{<ellipse}) {$print=1}
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

sub writeoverlaid(%)
{
	my $param=shift;
	my $mid = 14; # size/2
	open(my $fd, ">", $param->{filename}) or die $!;
	print $fd $basepic, qq'<g transform="rotate($param->{angle}, $mid, $mid) translate($param->{dx},$param->{dy}) scale($param->{scale})" style="opacity:0.7">', join "\n", @ovl, "</g>\n</svg>\n";
	close $fd;
}

my $scale = 6;
$basepic =~ s{<svg width="([0-9.]+)cm" height="([0-9.]+)cm"}{'<svg width="'.($1*$scale).'cm" height="'.($2*$scale).'cm"'}e;
$basepic =~ s{<svg}{$& shape-rendering="crispEdges"}; # disable anti-aliasing (but not for inkscape SVG export)

my %params=(
		filename=>"/dev/shm/test.svg",
		dx=>-7.0,
		dy=>7.0,
		scale=>0.099,
		angle=>0,
    );

sub optimize(%)
{
	my $params = shift;
	writeoverlaid($params);

#convert -density 450 nice.svg /dev/shm/nice.ppm
# using PerlMagick to read svg, measure darkened+brightened pixels
# use gaussian error method
	system(qq{( cd /dev/shm/ ; time gimp -inbdf '(python-fu-svgtopng RUN-NONINTERACTIVE "*.svg" "/dev/shm/")' -b '(gimp-quit 0)' )}); # slow part
	use Image::Magick;
	my $img = new Image::Magick;
	$img->Set(density=>400, antialias=>'false');
	$img->Read("/dev/shm/test.png");
	$img->Write("/dev/shm/test.ppm");
}
optimize(\%params);

$params{filename}="/dev/stdout";
writeoverlaid(\%params);

#inkscape --export-png=/dev/shm/test.png --export-dpi=200 --export-background-opacity=0 --without-gui /dev/shm/test.svg
