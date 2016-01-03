ASMSOURCES =	sample1.asm

OBJECTS	=	$(ASMSOURCES:.asm=.o)

LIBRARIES =
#-------------------------------------------------------------------------------
all :	$(OBJECTS) $(LIBRARIES)
	ld65 -o sample1.nes --config sample1.cfg --obj $(OBJECTS)
	./dd-img.sh sample1

.SUFFIXES : .asm .o

.asm.o :
	ca65 -t none $*.asm

clean :
	-rm sample1.nes
	-rm *.o

