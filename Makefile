#
#	3D Tutorial Makefile
# 

PC=fpc
PCFLAGS=

all: v3d

clean:
	-rm *.ppu *.o v3d gk

grdev.ppu: grdev.pas
	$(PC) $(PCFLAGS) grdev

gr3d.ppu: gr3d.pas
	$(PC) $(PCFLAGS) gr3d

gk: gk.pas
	$(PC) $(PCFLAGS) gk

v3d: grdev.ppu gr3d.ppu v3d.pas 
	$(PC) $(PCFLAGS) v3d.pas
