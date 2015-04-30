nice.svg: src.svg roundcorners.pl
	./roundcorners.pl $< > $@

src.svg:
	qrencode -m 1 -l L -t SVG https://conference.opensuse.org > $@


