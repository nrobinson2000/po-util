/*
 * Allows to set arbitrary speed for the serial device on Linux.
 * stty allows to set only predefined values: 9600, 19200, 38400, 57600, 115200, 230400, 460800.
 */
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <stropts.h>
#include <asm/termios.h>

int main(int argc, char* argv[]) {



    // int fd = open(argv[1], O_RDONLY);
    // printf("%i\n", fd );


    // int speed = atoi(argv[2]);

    struct termios2 tio;
    // ioctl(fd, TCGETS2, &tio);

    // tio.c_cflag &= ~CBAUD;
    // tio.c_cflag |= BOTHER;
    // // tio.c_ispeed = speed;
    // tio.c_ospeed = speed;

    int r = ioctl(open(argv[1], O_RDONLY), TCSETS2, &tio);

    // close(fd);

    if (r == 0) {
        printf("Opened and closed successfully.\n");
    } else {
        perror("ioctl");
    }
}
