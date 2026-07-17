// Minimal privileged reader for the Intel package RAPL energy counter.
// It accepts no arguments, opens one hard-coded sysfs file, immediately drops
// all capabilities, and prints the counter as an unsigned integer.

#include <errno.h>
#include <fcntl.h>
#include <linux/capability.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <unistd.h>

#define RAPL_ENERGY_FILE \
    "/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj"

static int drop_capabilities(void) {
    struct __user_cap_header_struct header = {
        .version = _LINUX_CAPABILITY_VERSION_3,
        .pid = 0,
    };
    struct __user_cap_data_struct data[2] = {{0}};

    return syscall(SYS_capset, &header, &data);
}

int main(int argc, char **argv) {
    char buffer[64];
    char *end = NULL;
    ssize_t length;

    if (argc != 1) {
        fprintf(stderr, "usage: %s\n", argv[0]);
        return 2;
    }

    int fd = open(RAPL_ENERGY_FILE, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fd < 0) {
        fprintf(stderr, "cannot open RAPL energy counter: %s\n", strerror(errno));
        return 1;
    }

    // The capability is only needed for open(). Remove it before parsing or
    // printing, and prevent this process from acquiring privileges again.
    if (drop_capabilities() != 0 || prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) != 0) {
        fprintf(stderr, "cannot drop capabilities: %s\n", strerror(errno));
        close(fd);
        return 1;
    }

    length = read(fd, buffer, sizeof(buffer) - 1);
    close(fd);
    if (length <= 0) {
        fprintf(stderr, "cannot read RAPL energy counter: %s\n", strerror(errno));
        return 1;
    }

    buffer[length] = '\0';
    errno = 0;
    unsigned long long energy = strtoull(buffer, &end, 10);
    if (errno != 0 || end == buffer || (*end != '\n' && *end != '\0')) {
        fprintf(stderr, "invalid RAPL energy value\n");
        return 1;
    }

    printf("%llu\n", energy);
    return 0;
}
