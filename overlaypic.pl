#!/usr/bin/perl -w
use strict;

while(<>) {
	last if m{</svg>};
	print;
}

print "</svg>\n";
