package io.mosip.registration.clientmanager.util;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.HashSet;
import java.util.Set;
import org.junit.Test;

import io.mosip.registration.clientmanager.constant.AuditEvent;
import io.mosip.registration.clientmanager.repository.GlobalParamRepository;

public class LivenessSettingsTest {

    @Test
    public void test_android_defaults_apply_when_server_values_absent() {
        GlobalParamRepository repo = mock(GlobalParamRepository.class); // every key answers null: the server sent nothing
        LivenessSettings s = new LivenessSettings(repo);
        assertTrue(s.enabled());
        assertEquals(3, s.maxRetries());
        assertEquals(0.80, s.passiveThreshold(), 0.0);
        assertFalse("face auth is new and stays off until switched on", s.faceAuthEnabled());
        assertTrue(new LivenessSettings(null).enabled());
    }

    @Test
    public void test_bad_values_fall_back_and_never_switch_liveness_off() {
        GlobalParamRepository repo = mock(GlobalParamRepository.class);
        when(repo.getCachedStringGlobalParam(LivenessSettings.ENABLED)).thenReturn("maybe");
        when(repo.getCachedStringGlobalParam(LivenessSettings.MAX_RETRIES)).thenReturn("zero");
        when(repo.getCachedStringGlobalParam(LivenessSettings.PASSIVE_THRESHOLD)).thenReturn("7");
        LivenessSettings s = new LivenessSettings(repo);
        assertTrue(s.enabled());
        assertEquals(3, s.maxRetries());
        assertEquals(0.80, s.passiveThreshold(), 0.0);
        when(repo.getCachedStringGlobalParam(LivenessSettings.ENABLED)).thenReturn("false");
        when(repo.getCachedStringGlobalParam(LivenessSettings.MAX_RETRIES)).thenReturn("5");
        assertFalse(s.enabled());
        assertEquals(5, s.maxRetries());
    }

    @Test
    public void test_android_audit_ids_unique() {
        Set<String> ids = new HashSet<>();
        for (AuditEvent e : AuditEvent.values()) {
            assertTrue("duplicate audit id " + e.getId(), ids.add(e.getId()));
        }
        assertEquals("REG-LIV-001", AuditEvent.REG_LIVENESS_START.getId());
    }

    @Test
    public void test_password_login_unchanged_when_face_auth_disabled() {
        // face authentication is OFF unless the server says exactly "true": the app then shows no face button and
        // the login, packet authentication and approval calls behave as before
        GlobalParamRepository repo = mock(GlobalParamRepository.class);
        assertFalse(new LivenessSettings(repo).faceAuthEnabled());
        when(repo.getCachedStringGlobalParam(LivenessSettings.FACE_AUTH_ENABLED)).thenReturn("yes");
        assertFalse(new LivenessSettings(repo).faceAuthEnabled());
        when(repo.getCachedStringGlobalParam(LivenessSettings.FACE_AUTH_ENABLED)).thenReturn("false");
        assertFalse(new LivenessSettings(repo).faceAuthEnabled());
        when(repo.getCachedStringGlobalParam(LivenessSettings.FACE_AUTH_ENABLED)).thenReturn("true");
        assertTrue(new LivenessSettings(repo).faceAuthEnabled());
    }

    @Test
    public void test_local_override_of_liveness_keys_is_ignored() {
        assertTrue(LivenessSettings.isServerOnlyKey("mosip.registration.liveness.enabled"));
        assertTrue(LivenessSettings.isServerOnlyKey("  MOSIP.registration.liveness.passive.threshold"));
        assertFalse(LivenessSettings.isServerOnlyKey("mosip.registration.scan_timeout"));
        assertFalse(LivenessSettings.isServerOnlyKey(null));
        java.util.Map<String, String> local = new java.util.HashMap<>();
        local.put("mosip.registration.liveness.enabled", "false");
        local.put("mosip.registration.liveness.passive.threshold", "0");
        local.put("mosip.registration.other", "x");
        java.util.Map<String, String> kept = LivenessSettings.withoutServerOnlyKeys(local);
        assertEquals(1, kept.size());
        assertEquals("x", kept.get("mosip.registration.other"));
        assertEquals(3, local.size()); // the input is untouched
        assertTrue(LivenessSettings.withoutServerOnlyKeys(null).isEmpty());
    }
}
