nice.svg: rounded.svg overlaypic.pl
	./overlaypic.pl openSUSE_geeko-color.svg $< > $@

rounded.svg: src.svg roundcorners.pl
	./roundcorners.pl $< > $@

src.svg:
	qrencode -m 1 -l L -t SVG https://conference.opensuse.org > $@

clean:
	rm -f src.svg rounded.svg nice.svg
