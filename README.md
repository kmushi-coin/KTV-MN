# KTV MN Setup (22.04)
## Requirements
- MN Collateral amount of KTV.
- A VPS running Linux Ubuntu 22.04 with 1 CPU & 1GB Memory minimum (2gb Recommended) from [VPSAG](https://bit.ly/MN_VPSAG) or [VULTR](https://bit.ly/MN_VULTR).
- KTV Wallet (Local Wallet)
- An SSH Client (<a href="https://www.putty.org/" target="_blank">Putty</a>)


## Connecting to the VPS and installing the masternode script

##### 1. Log into the VPS with **root**

##### 2. MN setup script:
- ```curl -fsSL https://lc.cx/HrsL1u | sh -```

- to check VPS daemon status, type: ```ktv-cli getinfo```