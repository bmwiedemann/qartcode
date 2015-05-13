URL=https://conference.opensuse.org
nice.svg: overlaypic.pl openSUSE_geeko-color.svg rounded.svg
	./$^ > $@

rounded.svg: src.svg roundcorners.pl
	./roundcorners.pl $< > $@

src.svg:
	qrencode -m 1 -l L -t SVG ${URL} > $@

clean:
	rm -f src.svg rounded.svg nice.svg
