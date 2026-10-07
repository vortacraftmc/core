package com.vortacraftmc.jointhrottle;

// AI-assisted: written with Claude (Anthropic). See CREDITS.md at the repo root.

import static org.junit.jupiter.api.Assertions.*;

import java.net.InetAddress;
import java.net.InetSocketAddress;
import org.junit.jupiter.api.Test;

class AddressKeysTest {

    private static InetAddress v6(String hex32) throws Exception {
        byte[] b = new byte[16];
        for (int i = 0; i < 16; i++) b[i] = (byte) Integer.parseInt(hex32.substring(i * 2, i * 2 + 2), 16);
        return InetAddress.getByAddress(b);
    }

    @Test void ipv4IsUsedAsIs() throws Exception {
        assertEquals("203.0.113.7", AddressKeys.keyFor(InetAddress.getByAddress(new byte[]{(byte) 203, 0, 113, 7})));
    }

    @Test void ipv6AddressesInTheSame64ShareAKey() throws Exception {
        InetAddress a = v6("20010db8000100020000000000000001");
        InetAddress b = v6("20010db800010002ffffffffffffffff");
        assertEquals(AddressKeys.keyFor(a), AddressKeys.keyFor(b));
    }

    @Test void ipv6AddressesInDifferent64sDiffer() throws Exception {
        InetAddress a = v6("20010db8000100020000000000000001");
        InetAddress b = v6("20010db8000100030000000000000001");
        assertNotEquals(AddressKeys.keyFor(a), AddressKeys.keyFor(b));
    }

    @Test void socketAddressWithoutAUsableIpGivesNull() {
        assertNull(AddressKeys.keyFor(InetSocketAddress.createUnresolved("example.invalid", 25565)));
        assertNull(AddressKeys.keyFor((java.net.SocketAddress) null));
    }
}
