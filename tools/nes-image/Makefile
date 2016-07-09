#IMAGE = pacman
IMAGE = donkey-kong
#IMAGE = smb

all :
	./dd-img.sh $(IMAGE)
	cp sample1-chr.hex ../../de0_cv_nes/
	cp sample1-prg.hex ../../de0_cv_nes/

    
run : all
	VirtuaNES.exe $(IMAGE).nes


clean :
	rm *.bin *.hex

