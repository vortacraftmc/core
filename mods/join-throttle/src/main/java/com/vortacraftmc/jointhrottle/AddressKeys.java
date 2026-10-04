package com.vortacraftmc.jointhrottle;

// AI-assisted: written with Claude (Anthropic). See CREDITS.md at the repo root.

import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.SocketAddress;

/**
 * Turns a connection's remote address into the key the limiter counts against.
 *
 * <p>IPv4 addresses are used as-is. IPv6 addresses are reduced to their /64
 * prefix: an IPv6 customer normally owns a whole /64, so keying on the full
 * 128-bit address would let one client dodge the limit by cycling through
 * addresses it already controls.
 */
public final class AddressKeys {

    private AddressKeys() {}

    /** @return the limiter key, or {@code null} if the address has no usable IP (then the caller must not throttle). */
    public static String keyFor(SocketAddress address) {
        if (address instanceof InetSocketAddress inet && inet.getAddress() != null) {
            return keyFor(inet.getAddress());
        }
        return null;
    }

    public static String keyFor(InetAddress address) {
        if (address instanceof Inet6Address) {
            byte[] raw = address.getAddress();
            StringBuilder sb = new StringBuilder("v6/");
            for (int i = 0; i < 8; i++) {
                sb.append(String.format("%02x", raw[i] & 0xff));
                if (i % 2 == 1 && i < 7) sb.append(':');
            }
            return sb.append("::/64").toString();
        }
        return address.getHostAddress();
    }
}
