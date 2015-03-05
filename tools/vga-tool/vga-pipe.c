#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include "vga.h"

void *vga_shm_get(void);
void vga_shm_free(void* addr);

int main(int argc, char **argv) {
    int fd;
    int dump = 0;
    struct rgb15 *disp_data;
    struct rgb15 *col;
    int x, y;

    printf("%s\n", argv[0]);
    if (argc >= 2) {
        if (strcmp(argv[1], "-h") == 0) {
            printf("%s -d: output log\n", argv[0]);
            return -2;
        }
        if (strcmp(argv[1], "-d") == 0) {
            dump = 1;
        }
    }
    system("test ! -e vga-port && mkfifo vga-port");

    if((disp_data = (struct rgb15 *)vga_shm_get()) == NULL)
    {
        perror("error attaching shared memory.\n");
        return -1;
    }

    fd = open("vga-port", O_RDONLY);
    if (!fd) {
        perror("error openning pipe!\n");
        return -1;
    }

    x = y = 0;
    col = disp_data;
    while(1) {
        int len;
        char buf[4];

        memset(buf, 0, sizeof(buf));
        len = read(fd, buf, sizeof(buf));
        //printf("len:%d\n", len);
        if (len == 0) {
            struct timespec sleep_inteval = {0, 100000000};
            nanosleep(&sleep_inteval, NULL);
            continue;
        } 
        //printf("buf:[%s]\n", buf);
        if (buf[0] == '-') {
            if (dump) {
                printf("hsync\n");
            }
            x = 0;
            y++;
            if (y == 525) {
                y = 0;
            }
        }
        else if (buf[0] == '_') {
            if (dump) {
                printf("vsync\n");
            }
            //vga widht + fp + 1.
            y = 480 + 10 + 1;
            col = disp_data;
        }
        else {
            unsigned int rgb12;
            unsigned char r, g, b;

            sscanf(buf, "%x", &rgb12);

            r = (rgb12 & 0x0f) * 0x1f / 0x0f;
            g = ((rgb12 >> 4) & 0x0f) * 0x1f / 0x0f;
            b = ((rgb12 >> 8) & 0x0f) * 0x1f / 0x0f;
            if (dump) {
                printf("%d,%d: %03x, %02x%02x%02x\n", x, y,rgb12, 
                        (unsigned int)r, (unsigned int)g, (unsigned int)b);
            }

            col->r = r;
            col->g = g;
            col->b = b;
/*
            col->r = 0xff;
            col->g = 0xff;
            col->b = 0xff;
*/

            col++;
            x++;
            if (col - disp_data >= 640 * 480)
                col = disp_data;
        }
    }
    return 0;
}


