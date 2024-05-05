#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/bpf.h>
#include <bpf/bpf.h>

#define MAP_NAME "unutilized_count_map"

int main() {
    int map_fd;
    long long unutilized_count = 0;
    long long *values;

    map_fd = bpf_obj_get("/sys/fs/bpf/" MAP_NAME);
    if (map_fd < 0) {
        perror("bpf_obj_get");
        return 1;
    }

    int ncpus = libbpf_num_possible_cpus();
    if (ncpus < 0) {
        perror("libbpf_num_possible_cpus");
        return 1;
    }

    values = calloc(ncpus, sizeof(long long));
    if (!values) {
        perror("calloc");
        return 1;
    }

    if (bpf_map_lookup_elem(map_fd, &(int){0}, values)) {
        perror("bpf_map_lookup_elem");
        return 1;
    }

    for (int i = 0; i < ncpus; i++) {
        unutilized_count += values[i];
    }

    printf("Total unutilized byte count: %lld\n", unutilized_count);

    free(values);
    close(map_fd);

    return 0;
}
