
DIRS=mem cpu/alu cpu 
WORKDIR=work

ROOT_DIR=$(CURDIR)
	
all:
	for dir in $(DIRS); do \
		make -C $(ROOT_DIR)/$$dir; \
	done

clean:
	-rm $(WORKDIR)/*

