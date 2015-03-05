
BIN=vga-pipe

OBJS=vga-pipe.o vgashm.o
	 
CFLAGS=-g -Wall

LFLAGS=-g

all:	$(BIN)

$(BIN): $(OBJS)
	gcc -o $(BIN) $(OBJS) $(LFLAGS)

.c.o: 
	gcc $(CFLAGS) -c $<

clean:
	-rm $(OBJS) $(BIN)
		
tag:
	make tag


