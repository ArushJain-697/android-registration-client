package io.mosip.registration.clientmanager.util;

import io.mosip.registration.clientmanager.repository.GlobalParamRepository;

/**
 * SAJEEV liveness settings from the client's global parameters (synced from the server), each with a client-side default so
 * the client works when the server sends nothing. A missing or invalid value never turns liveness off: only the exact
 * value "false" does.
 */
public class LivenessSettings {

    public static final String PREFIX = "mosip.registration.liveness.";
    public static final String ENABLED = PREFIX + "enabled";
    public static final String MAX_RETRIES = PREFIX + "maxRetries";
    public static final String PASSIVE_THRESHOLD = PREFIX + "passive.threshold";
    public static final String FACE_AUTH_ENABLED = PREFIX + "faceAuth.enabled";

    public static final boolean DEFAULT_ENABLED = true;
    public static final int DEFAULT_MAX_RETRIES = 3;
    public static final double DEFAULT_PASSIVE_THRESHOLD = 0.80;
    /** Face login and approval are new on Android and stay off until switched on, so the password path is unchanged. */
    public static final boolean DEFAULT_FACE_AUTH_ENABLED = false;

    private final GlobalParamRepository params;

    public LivenessSettings(GlobalParamRepository params) {
        this.params = params;
    }

    private String raw(String key) {
        try {
            return params == null ? null : params.getCachedStringGlobalParam(key);
        } catch (RuntimeException e) {
            return null;
        }
    }

    public boolean enabled() {
        String v = raw(ENABLED);
        return v == null || !"false".equalsIgnoreCase(v.trim());
    }

    public boolean faceAuthEnabled() {
        String v = raw(FACE_AUTH_ENABLED);
        return v == null ? DEFAULT_FACE_AUTH_ENABLED : "true".equalsIgnoreCase(v.trim());
    }

    public int maxRetries() {
        try {
            String v = raw(MAX_RETRIES);
            int n = v == null ? DEFAULT_MAX_RETRIES : Integer.parseInt(v.trim());
            return n < 1 ? DEFAULT_MAX_RETRIES : n;
        } catch (NumberFormatException e) {
            return DEFAULT_MAX_RETRIES;
        }
    }

    public double passiveThreshold() {
        try {
            String v = raw(PASSIVE_THRESHOLD);
            double d = v == null ? DEFAULT_PASSIVE_THRESHOLD : Double.parseDouble(v.trim());
            return d <= 0 || d > 1 ? DEFAULT_PASSIVE_THRESHOLD : d;
        } catch (NumberFormatException e) {
            return DEFAULT_PASSIVE_THRESHOLD;
        }
    }
}
