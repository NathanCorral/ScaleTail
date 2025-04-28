# Pi-hole with Tailscale Sidecar Configuration

This Docker Compose configuration sets up [Pi-hole](https://github.com/pi-hole/pi-hole) with Tailscale as a sidecar container to securely manage and access your network-wide ad blocker over a private Tailscale network. By using Tailscale in a sidecar configuration, you can enhance the security and privacy of your Pi-hole instance, ensuring that it is only accessible within your Tailscale network.

## Pi-hole

[Pi-hole](https://github.com/pi-hole/pi-hole) is a network-wide ad blocker that acts as a DNS sinkhole, filtering out ads and trackers across all devices on your local network. It improves your browsing experience by blocking unwanted content before it even reaches your device. This configuration leverages Tailscale to securely connect to your Pi-hole instance, ensuring that your DNS requests and administrative interface are protected from unauthorized access.

## Configuration Overview

In this setup, the `tailscale-pihole` service runs Tailscale, which manages secure networking for the Pi-hole service. The `pihole` service uses the Tailscale network stack via Docker's `network_mode: service:` configuration. This setup ensures that Pi-hole’s DNS service and web interface are only accessible through the Tailscale network (or locally, if preferred), providing an extra layer of security and privacy for your network-wide ad blocker.

## Binding to your local host machine? Port 53 - DNSStubListener

In Debian (e.g. Ubuntu Server 22.04.x / 24.04.x) systems, particularly when using systemd-resolved for DNS resolution, a DNS stub listener is employed by default to provide local DNS resolution through the loopback address (localhost). This stub listener binds to port 53 on the local interface 127.0.0.53, allowing local applications to send DNS queries to this address for resolution.

### What is DNSStubListener?

`DNSStubListener` is a configuration option in the `/etc/systemd/resolved.conf` file that controls whether the `systemd-resolved` service will listen for DNS queries on the loopback address (127.0.0.53) over port 53.

- **DNSStubListener=yes**: When this option is enabled, `systemd-resolved` binds to `127.0.0.53:53`. This allows the system to use `systemd-resolved` as a local DNS resolver for local DNS queries.

- **DNSStubListener=no**: Disabling the stub listener prevents `systemd-resolved` from binding to port 53 on the local interface, freeing up this port for other DNS services or applications that require direct control over port 53.

### Why Change `DNSStubListener` to `no`?

In certain scenarios, such as when running a local DNS server (e.g., AdguardHome, PiHole, BIND, Unbound, or Dnsmasq) or any other application that requires exclusive access to port 53 on all interfaces, `systemd-resolved`'s binding to the local DNS port can cause conflicts. For example, if you plan to run your own DNS server on the same machine, that service needs to bind to port 53 globally, including the loopback interface. With `systemd-resolved` already occupying this port, the new DNS service would fail to start or function properly.

To resolve this issue, you need to disable `systemd-resolved` from binding to port 53 by setting `DNSStubListener=no` in the `/etc/systemd/resolved.conf` file.

### Steps to Free Up Port 53

1. **Open the configuration file**:

   ```bash
   sudo nano /etc/systemd/resolved.conf
   ```

2. **Modify the `DNSStubListener` setting**:

   Find the line containing `#DNSStubListener=yes` (it might be commented out by default) and change it to:

   ```bash
   DNSStubListener=no
   ```

3. **Restart the `systemd-resolved` service**:
   After saving the changes, restart the service for the changes to take effect:

   ```bash
   sudo systemctl restart systemd-resolved
   ```

4. **Verify Port 53 is Free**:

   You can check that port 53 is no longer bound by `systemd-resolved` by running:

   ```bash
   sudo netstat -tuln | grep :53
   ```

If the configuration was successful, no process should be listed as using port 53 on the loopback interface.
