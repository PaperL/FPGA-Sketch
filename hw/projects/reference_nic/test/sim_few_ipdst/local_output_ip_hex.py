import logging
import random
from scapy.all import RandIP
import ipaddress

logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
random.seed(123123)

# set parameters
SA = "aa:bb:cc:dd:ee:ff"
DA = "00:cc:aa:23:11:02"
nextHopMAC = "dd:55:dd:66:dd:77"
SRC_IP = "192.168.0.1"
TTL = 64

TARGET_IP = "192.168.1.1"
NUM_IP_CORRECT = 17
NUM_IP_WRONG_LAN = 7
NUM_IP_WRONG_WAN = 11
NUM_PKTS = NUM_IP_CORRECT + NUM_IP_WRONG_LAN + NUM_IP_WRONG_WAN

random_ips = []  # Fixed by random.seed
while len(random_ips) < NUM_PKTS:
    if len(random_ips) < NUM_IP_WRONG_LAN:
        random_ip = RandIP("192.168.1.0/24")._fix()
        if random_ip != TARGET_IP:
            random_ips.append(random_ip)
    elif len(random_ips) < NUM_IP_WRONG_LAN + NUM_IP_WRONG_WAN:
        random_ip = RandIP("0.0.0.0/0")._fix()
        if random_ip != TARGET_IP:
            random_ips.append(random_ip)
    else:
        random_ips.append(TARGET_IP)

random.shuffle(random_ips)
targetIpHex = [
    int.from_bytes(ipaddress.ip_address(ip_str).packed) for ip_str in random_ips
]

for i in range(len(random_ips)):
    print(random_ips[i].rjust(20), "\t", "0x{:08X}".format(targetIpHex[i]))