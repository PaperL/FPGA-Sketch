#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <bpf/bpf_helpers.h>

#define MPS 512

struct bpf_map_def SEC("maps") unutilized_count_map = {
    .type = BPF_MAP_TYPE_PERCPU_ARRAY,
    .key_size = sizeof(int),
    .value_size = sizeof(__u64),
    .max_entries = 1,
};

SEC("prog")
int xdp_prog(struct __sk_buff *skb) {
    int key = 0;
    __u64 *unutilized_count;

    unutilized_count = bpf_map_lookup_elem(&unutilized_count_map, &key);
    if (!unutilized_count) {
        return XDP_DROP;
    }

    __u64 pcie_packets = (skb->len + MPS - 1) / MPS;
    __u64 unutilized_bytes = pcie_packets * MPS - skb->len;

    *unutilized_count += unutilized_bytes;

    return XDP_PASS;
}

char _license[] SEC("license") = "GPL";
