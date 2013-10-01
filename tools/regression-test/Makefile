ASMSOURCES =	regression.asm

OBJECTS	=	$(ASMSOURCES:.asm=.o)

LIBRARIES =
#-------------------------------------------------------------------------------
all :	$(OBJECTS) $(LIBRARIES)
	ld65 -o regression.nes --config sample1.cfg --obj $(OBJECTS)

.SUFFIXES : .asm .o

.asm.o :
	ca65 -t none $*.asm

clean :
	-rm *.nes
	-rm *.o

