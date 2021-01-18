all:	play_dvbt

clean:
	rm -f *.o *.inc *.so *.c~ *.h~
	indent -linux -c 60 -brf -l 132

INCLUDEFLAGS2=-lpthread -I/opt/vc/include -I/opt/vc/include/interface/vmcs_host/linux -I/opt/vc/include/interface/vcos/pthreads -I..
LIBFLAGS2=-L/opt/vc/lib -lbcm_host -lpthread  -ljpeg -lrt -lm -ldl -lfftw3f -lwiringPi

play_dvbt: play_dvbt.c 
	gcc -Wall $(INCLUDEFLAGS2) -o  play_dvbt \
		play_dvbt.c $(LIBFLAGS2) 

#install:
#	cp rpidatvgui ../../bin/