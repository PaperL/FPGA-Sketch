```
clang -O2 -target bpf -c ub_counter.c -o ub_counter.o
bpftool prog load ub_counter.o /sys/fs/bpf/ub_counter

ip link set dev eth0 xdp obj /sys/fs/bpf/ub_counter

bpftool map dump id $(bpftool map show | grep unutilized_count_map | awk '{print \$1}') | awk '{sum += \$2} END {print sum}'
```

