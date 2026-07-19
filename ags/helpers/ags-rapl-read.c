// Minimal privileged CPU package-energy reader.
//
// It accepts no arguments and reads only a fixed package-energy counter. It
// first tries common Linux powercap paths (Intel and AMD drivers use the same
// RAPL interface), then falls back to the fixed Intel/AMD package-energy MSRs.
// Capabilities are dropped immediately after opening the selected source.
// Output is: ENERGY_UJ MAX_ENERGY_RANGE_UJ

#if defined(__i386__) || defined(__x86_64__)
#include <cpuid.h>
#define AGS_X86 1
#else
#define AGS_X86 0
#endif

#include <errno.h>
#include <fcntl.h>
#include <linux/capability.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <unistd.h>

#define AMD_RAPL_POWER_UNIT 0xC0010299U
#define AMD_PKG_ENERGY_STATUS 0xC001029BU
#define INTEL_RAPL_POWER_UNIT 0x00000606U
#define INTEL_PKG_ENERGY_STATUS 0x00000611U

struct powercap_path {
    const char *energy;
    const char *maximum;
};

static const struct powercap_path powercap_paths[] = {
    {
        "/sys/class/powercap/intel-rapl:0/energy_uj",
        "/sys/class/powercap/intel-rapl:0/max_energy_range_uj",
    },
    {
        "/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj",
        "/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/max_energy_range_uj",
    },
    {
        "/sys/class/powercap/amd-rapl:0/energy_uj",
        "/sys/class/powercap/amd-rapl:0/max_energy_range_uj",
    },
    {
        "/sys/devices/virtual/powercap/amd-rapl/amd-rapl:0/energy_uj",
        "/sys/devices/virtual/powercap/amd-rapl/amd-rapl:0/max_energy_range_uj",
    },
};

static int drop_capabilities(void) {
    struct __user_cap_header_struct header = {
        .version = _LINUX_CAPABILITY_VERSION_3,
        .pid = 0,
    };
    struct __user_cap_data_struct data[2] = {{0}};

    return syscall(SYS_capset, &header, &data);
}

static int lock_down(void) {
    if (drop_capabilities() != 0) {
        return -1;
    }
    return prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0);
}

static int read_uint64_fd(int fd, uint64_t *value) {
    char buffer[64];
    char *end = NULL;
    ssize_t length = read(fd, buffer, sizeof(buffer) - 1);

    if (length <= 0) {
        return -1;
    }
    buffer[length] = '\0';
    errno = 0;
    unsigned long long parsed = strtoull(buffer, &end, 10);
    if (errno != 0 || end == buffer || (*end != '\n' && *end != '\0')) {
        return -1;
    }
    *value = (uint64_t)parsed;
    return 0;
}

static int try_powercap(void) {
    for (size_t i = 0; i < sizeof(powercap_paths) / sizeof(powercap_paths[0]); i++) {
        int energy_fd = open(powercap_paths[i].energy,
                             O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
        if (energy_fd < 0) {
            continue;
        }
        int maximum_fd = open(powercap_paths[i].maximum,
                              O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
        if (maximum_fd < 0) {
            close(energy_fd);
            continue;
        }
        if (lock_down() != 0) {
            close(energy_fd);
            close(maximum_fd);
            return -1;
        }

        uint64_t energy = 0;
        uint64_t maximum = 0;
        int result = read_uint64_fd(energy_fd, &energy) == 0 &&
                     read_uint64_fd(maximum_fd, &maximum) == 0 && maximum > 0;
        close(energy_fd);
        close(maximum_fd);
        if (!result) {
            return -1;
        }
        printf("%llu %llu\n",
               (unsigned long long)energy,
               (unsigned long long)maximum);
        return 0;
    }
    return 1;
}

#if AGS_X86
static int cpu_vendor(char vendor[13]) {
    unsigned int eax = 0;
    unsigned int ebx = 0;
    unsigned int ecx = 0;
    unsigned int edx = 0;
    if (__get_cpuid(0, &eax, &ebx, &ecx, &edx) == 0) {
        return -1;
    }
    memcpy(vendor, &ebx, 4);
    memcpy(vendor + 4, &edx, 4);
    memcpy(vendor + 8, &ecx, 4);
    vendor[12] = '\0';
    return 0;
}

static int read_msr(int fd, uint32_t address, uint64_t *value) {
    ssize_t length = pread(fd, value, sizeof(*value), (off_t)address);
    return length == (ssize_t)sizeof(*value) ? 0 : -1;
}

static int try_msr(void) {
    char vendor[13];
    uint32_t unit_address;
    uint32_t energy_address;

    if (cpu_vendor(vendor) != 0) {
        return -1;
    }
    if (strcmp(vendor, "AuthenticAMD") == 0) {
        unit_address = AMD_RAPL_POWER_UNIT;
        energy_address = AMD_PKG_ENERGY_STATUS;
    } else if (strcmp(vendor, "GenuineIntel") == 0) {
        unit_address = INTEL_RAPL_POWER_UNIT;
        energy_address = INTEL_PKG_ENERGY_STATUS;
    } else {
        return -1;
    }

    int fd = open("/dev/cpu/0/msr", O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fd < 0) {
        return -1;
    }
    if (lock_down() != 0) {
        close(fd);
        return -1;
    }

    uint64_t unit_msr = 0;
    uint64_t energy_msr = 0;
    if (read_msr(fd, unit_address, &unit_msr) != 0 ||
        read_msr(fd, energy_address, &energy_msr) != 0) {
        close(fd);
        return -1;
    }
    close(fd);

    unsigned int energy_exponent = (unsigned int)((unit_msr >> 8) & 0x1fU);
    if (energy_exponent >= 32) {
        return -1;
    }
    uint64_t energy_ticks = energy_msr & UINT32_MAX;
    uint64_t energy_uj = (energy_ticks * 1000000ULL) >> energy_exponent;
    uint64_t maximum_uj = ((1ULL << 32) * 1000000ULL) >> energy_exponent;
    if (maximum_uj == 0) {
        return -1;
    }

    printf("%llu %llu\n",
           (unsigned long long)energy_uj,
           (unsigned long long)maximum_uj);
    return 0;
}
#else
static int try_msr(void) {
    return -1;
}
#endif

int main(int argc, char **argv) {
    if (argc != 1) {
        fprintf(stderr, "usage: %s\n", argv[0]);
        return 2;
    }

    int powercap_result = try_powercap();
    if (powercap_result == 0) {
        return 0;
    }
    // try_powercap() drops capabilities only after opening a usable source.
    // A negative result therefore means a selected source failed after the
    // privilege drop and no safe fallback remains.
    if (powercap_result < 0) {
        fprintf(stderr, "cannot read CPU package energy from powercap\n");
        return 1;
    }
    if (try_msr() == 0) {
        return 0;
    }

    fprintf(stderr, "no readable Intel/AMD CPU package-energy source\n");
    return 1;
}
