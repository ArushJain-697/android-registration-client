package io.mosip.registration.clientmanager.util;

import java.util.HashMap;
import java.util.Map;
import java.util.function.LongSupplier;

/**
 * SAJEEV A5: attempt limit for face authentication (login, packet authentication, approval). Per user: after
 * {@code maxFailures} failed face attempts (no match, or liveness refused) the user's face authentication is locked for
 * {@code lockMillis}. The password path is not touched (the normal password lockout still applies there). A success
 * clears the user's counter. Pure logic, monotonic clock (not the wall clock), thread safe.
 */
public class FaceAuthLockout {

    public static final long DEFAULT_LOCK_MILLIS = 5 * 60 * 1000L;

    private static final class Entry {
        int failures;
        long lockedUntil; // monotonic millis; 0 = not locked
        boolean locked;
    }

    private final LongSupplier clock;
    private final long lockMillis;
    private final Map<String, Entry> users = new HashMap<>();

    public FaceAuthLockout(long lockMillis) {
        this(lockMillis, () -> System.nanoTime() / 1_000_000L);
    }

    public FaceAuthLockout(long lockMillis, LongSupplier monotonicMillis) {
        this.lockMillis = lockMillis <= 0 ? DEFAULT_LOCK_MILLIS : lockMillis;
        this.clock = monotonicMillis;
    }

    private static String key(String userId) {
        return userId == null ? "" : userId.trim().toLowerCase();
    }

    /** True while the user may not try face authentication. An expired lock is cleared (a fresh start). */
    public synchronized boolean isLocked(String userId) {
        Entry e = users.get(key(userId));
        if (e == null || !e.locked) {
            return false;
        }
        if (clock.getAsLong() - e.lockedUntil >= 0) {
            users.remove(key(userId));
            return false;
        }
        return true;
    }

    /** Records one failed face attempt; the maxFailures-th failure starts the lock window. Returns true if now locked. */
    public synchronized boolean recordFailure(String userId, int maxFailures) {
        int max = maxFailures < 1 ? 3 : maxFailures;
        if (isLocked(userId)) {
            return true;
        }
        Entry e = users.computeIfAbsent(key(userId), k -> new Entry());
        e.failures++;
        if (e.failures >= max) {
            e.locked = true;
            e.lockedUntil = clock.getAsLong() + lockMillis;
            return true;
        }
        return false;
    }

    /** A successful face authentication clears the user's failures. */
    public synchronized void recordSuccess(String userId) {
        users.remove(key(userId));
    }

    public synchronized int failures(String userId) {
        Entry e = users.get(key(userId));
        return e == null ? 0 : e.failures;
    }
}
