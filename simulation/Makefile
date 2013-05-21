
DIRS=cpu/alu cpu mem
WORKDIR=work

ROOT_DIR=$(CURDIR)
	
all:
	for dir in $(DIRS); do \
		make -C $(ROOT_DIR)/$$dir; \
	done

clean:
	-rm $(WORKDIR)/*

