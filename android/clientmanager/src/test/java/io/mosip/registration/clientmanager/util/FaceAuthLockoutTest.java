package io.mosip.registration.clientmanager.util;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.util.concurrent.atomic.AtomicLong;
import org.junit.Test;

public class FaceAuthLockoutTest {

    private final AtomicLong now = new AtomicLong(1000);
    private final FaceAuthLockout l = new FaceAuthLockout(300_000L, now::get);

    @Test
    public void test_lock_after_max_failures_and_not_before() {
        assertFalse(l.recordFailure("u1", 3));
        assertFalse(l.recordFailure("u1", 3));
        assertFalse(l.isLocked("u1"));
        assertTrue(l.recordFailure("u1", 3));
        assertTrue(l.isLocked("u1"));
    }

    @Test
    public void test_lock_is_per_user() {
        for (int i = 0; i < 3; i++) l.recordFailure("u1", 3);
        assertTrue(l.isLocked("u1"));
        assertFalse(l.isLocked("u2"));
        assertTrue("user ids compare ignoring case and spaces", l.isLocked(" U1 "));
    }

    @Test
    public void test_lock_expires_after_window_and_starts_fresh() {
        for (int i = 0; i < 3; i++) l.recordFailure("u1", 3);
        now.addAndGet(299_999);
        assertTrue(l.isLocked("u1"));
        now.addAndGet(1);
        assertFalse(l.isLocked("u1"));
        assertEquals(0, l.failures("u1"));
        assertFalse(l.recordFailure("u1", 3));
    }

    @Test
    public void test_success_clears_counter() {
        l.recordFailure("u1", 3);
        l.recordFailure("u1", 3);
        l.recordSuccess("u1");
        assertEquals(0, l.failures("u1"));
        assertFalse(l.recordFailure("u1", 3));
    }

    @Test
    public void test_bad_max_falls_back_to_three() {
        assertFalse(l.recordFailure("u1", 0));
        assertFalse(l.recordFailure("u1", -5));
        assertTrue(l.recordFailure("u1", 0));
    }
}
