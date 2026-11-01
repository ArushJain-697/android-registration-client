package io.mosip.registration.clientmanager.dao;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import java.util.HashMap;
import java.util.Map;
import org.junit.Test;

import io.mosip.registration.clientmanager.entity.LocalPreferences;
import io.mosip.registration.clientmanager.repository.LocalPreferencesRepository;
import io.mosip.registration.clientmanager.repository.PermittedLocalConfigRepository;

/** SAJEEV A4: a local preference can never override a server-only liveness setting. */
public class LocalConfigDAOLivenessTest {

    @Test
    public void test_modifyConfigurations_refuses_liveness_keys() {
        LocalPreferencesRepository prefs = mock(LocalPreferencesRepository.class);
        LocalConfigDAOImpl dao = new LocalConfigDAOImpl(mock(PermittedLocalConfigRepository.class), prefs);
        Map<String, String> m = new HashMap<>();
        m.put("mosip.registration.liveness.enabled", "false");
        m.put("mosip.registration.liveness.passive.threshold", "0");
        dao.modifyConfigurations(m);
        verify(prefs, never()).save(any(LocalPreferences.class));
    }

    @Test
    public void test_modifyConfigurations_still_saves_other_keys() {
        LocalPreferencesRepository prefs = mock(LocalPreferencesRepository.class);
        LocalConfigDAOImpl dao = new LocalConfigDAOImpl(mock(PermittedLocalConfigRepository.class), prefs);
        Map<String, String> m = new HashMap<>();
        m.put("mosip.registration.liveness.enabled", "false");
        m.put("mosip.registration.scan_timeout", "9");
        dao.modifyConfigurations(m);
        verify(prefs, times(1)).save(any(LocalPreferences.class));
    }
}
