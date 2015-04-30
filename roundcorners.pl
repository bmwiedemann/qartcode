#!/usr/bin/perl -w
use strict;
use Data::Dump qw(dump);

our $strokewidth = 1/8 + 1/4; # round number, large enough to cover a corner
our $cornerdistance = 0.5;
our $curviness = 0.15;
my $overlap = 0.05;

my @data=();
my ($sizex, $sizey);
# parse SVG into @data
while(<>) {
	if (m'<rect x="0" y="0" width="(\d+)" height="(\d+)" fill="#ffffff" />') {
		($sizex, $sizey) = ($1, $2);
		foreach my $y (0..($sizey-1)) {
			foreach my $x (0..($sizex-1)) {
				$data[$y][$x]=1; # white
			}
		}
	}
	if (m'<rect x="(\d+)" y="(\d+)" width="1" height="1" fill="#000000" />') {
		my ($x, $y) = ($1, $2);
		$data[$y][$x]=0; # black
		my $newsize = 1+$overlap;
		if($x && $data[$y][$x-1]==0) {
			s/(width)="1"/$1="$newsize"/g;
			my $newx = $x-$overlap;
			s/(x)="\d+"/$1="$newx"/;
		}
		if($y && $data[$y-1][$x]==0) {
			s/(height)="1"/$1="$newsize"/g;
			$y-=$overlap;
			s/(y)="\d+"/$1="$y"/;
		}
	}
	last if m{</svg>};
	print;
}
#print dump(@data);


# direction value maps to 45+d*90 degrees so
#   2   3
#     p
#   1   0
#

my %dirmap=(
	0=>[+1,+1],
	1=>[-1,+1],
	2=>[-1,-1],
	3=>[+1,-1],
	);

sub not4($) { 15-$_[0] }

sub svgcolor($)
{ sprintf("#%06x", 0xffffff*$_[0]) }

sub output(@)
{ print @_,"\n"; }

sub curve(%)
{
	my ($params) = @_;
	my $dir = $dirmap{$params->{dir}};
	#return if $params->{dir} != 1; # debug
	#dump $params, $dir; # debug
	my $swh = $strokewidth / 2;
	my $offs = $cornerdistance + $swh;
	my @f = ($dir->[0], -$dir->[1]);
	my @curvestart = ($params->{x} + $f[0]*$cornerdistance, $params->{y} + $f[1]*$swh);
	my @center = (-$f[0]*$cornerdistance, -$f[1]*$swh);
	for my $i (0..1) { $center[$i] -= $dir->[$i]*$curviness }
	my @offs=(-$f[0]*$offs, -$f[1]*$offs);
	my $c = svgcolor($params->{color});
# smooth black top-left to bottom-right
#  <path style="stroke:#000000;fill:none;stroke-width:0.3125px;stroke-opacity:1" d="m 14.50,10.16 c -0.5,-0.16 -0.66,-0.66 -0.66,-0.66" />
	output(qq'<path style="fill:none;stroke:$c;stroke-width:${strokewidth}px;stroke-opacity:1" d="m $curvestart[0],$curvestart[1] c $center[0],$center[1] $offs[0],$offs[1] $offs[0],$offs[1]" />');
}

sub doublecurve(%)
{
	my $params = shift;
	my %params = %$params;
	local $curviness=0;
	curve(\%params);
	$params{dir} = ($params{dir} + 2) % 4; # opposite direction
	curve(\%params);
}

# maps bits to function
my %adjustmap=(
	#(1=>{function=>\&curve, params=>{dir=>0, color=>1}});
	5=>{function=>\&doublecurve, params=>{dir=>0, color=>0}},
	10=>{function=>\&doublecurve, params=>{dir=>0, color=>1}},
);
for my $i (0..3) {
	$adjustmap{1<<$i} = {function=>\&curve, params=>{dir=>$i, color=>0}};
	$adjustmap{not4(1<<$i)} = {function=>\&curve, params=>{dir=>$i, color=>1}};
}

foreach my $y (0..($sizey-2)) {
	foreach my $x (0..($sizex-2)) {
		# collect 2x2 bits and look it up in adjustmap
		my $bits =
			($data[$y][$x+1] << 3) +
			($data[$y][$x]   << 2) +
			($data[$y+1][$x] << 1) +
			$data[$y+1][$x+1];
		my $m=$adjustmap{$bits};
		next unless $m;
		my %params = %{$m->{params}};
		$params{x}=$x+1;
		$params{y}=$y+1;
		&{$m->{function}}(\%params);
	}
}

print "</svg>\n";

