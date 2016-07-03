ASMSOURCES =	sample1.asm

OBJECTS	=	$(ASMSOURCES:.asm=.o)

LIBRARIES =
#-------------------------------------------------------------------------------
all :	$(OBJECTS) $(LIBRARIES)
	ld65 -o sample1.nes --config sample1.cfg --obj $(OBJECTS)

.SUFFIXES : .asm .o

.asm.o :
	ca65 -t none $*.asm

clean :
	-rm sample1.nes
	-rm *.o
	-rm *.hex
	-rm *.bin

