/*
 * SAJEEV liveness bridge (ticket #52). Copyright (c) SAJEEV contributors. MPL-2.0.
 */

package io.mosip.registration_client.api_services;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import javax.inject.Inject;
import javax.inject.Singleton;

import io.flutter.plugin.common.BinaryMessenger;
import io.mosip.registration_client.model.LivenessPigeon;
import io.sajeev.engine.android.AndroidLivenessController;

/** Host side of the liveness pigeon. Engine work runs on a worker thread, never the platform main thread. */
@Singleton
public class LivenessApi implements LivenessPigeon.LivenessApi {

    static final String SBI_PACKAGE = "io.mosip.mock.sbi";
    static final String FEED_CLASS = "io.mosip.mock.sbi.feed.FrameFeedService";

    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private AndroidLivenessController controller;
    private LivenessPigeon.LivenessEvents events;
    private final io.sajeev.session.LiveGate liveGate = new io.sajeev.session.LiveGate();

    @Inject
    public LivenessApi() {
    }

    /** Called from MainActivity once the Flutter engine exists. */
    public synchronized void attach(Context context, BinaryMessenger messenger) {
        events = new LivenessPigeon.LivenessEvents(messenger);
        controller = new AndroidLivenessController(context, SBI_PACKAGE, FEED_CLASS, this::engineProperties, (id, p) -> {
            if ("LIVE".equals(p.phase)) {
                liveGate.markLive(id);
            }
            events.onProgress(id, toDto(p), new LivenessPigeon.LivenessEvents.Reply<Void>() {
                @Override
                public void reply(Void v) {
                    // fire and forget
                }
            });
        });
    }

    private volatile io.mosip.registration.clientmanager.repository.GlobalParamRepository params;

    /** The client's global parameters, so the engine follows the client's liveness settings (set by BiometricsDetailsApi). */
    public void useGlobalParams(io.mosip.registration.clientmanager.repository.GlobalParamRepository repository) {
        this.params = repository;
    }

    /** Every engine setting the client holds (mosip.registration.liveness.*, with .resident/.operator/.supervisor overrides). */
    java.util.Properties engineProperties() {
        java.util.Properties p = new java.util.Properties();
        io.mosip.registration.clientmanager.repository.GlobalParamRepository r = params;
        if (r == null) {
            return p;
        }
        for (String key : io.sajeev.policy.Config.DEFAULTS.keySet()) {
            put(p, r, key);
            for (String w : io.sajeev.policy.Config.WORKFLOWS) {
                put(p, r, key + "." + w);
            }
        }
        return p;
    }

    private static void put(java.util.Properties p, io.mosip.registration.clientmanager.repository.GlobalParamRepository r, String suffix) {
        try {
            String v = r.getCachedStringGlobalParam(io.sajeev.policy.Config.PREFIX + suffix);
            if (v != null && !v.trim().isEmpty()) {
                p.setProperty(io.sajeev.policy.Config.PREFIX + suffix, v.trim());
            }
        } catch (RuntimeException ignored) {
            // a missing parameter keeps the engine default
        }
    }

    static LivenessPigeon.LivenessProgressDto toDto(AndroidLivenessController.Progress p) {
        LivenessPigeon.LivenessProgressDto.Builder b = new LivenessPigeon.LivenessProgressDto.Builder();
        b.setPhase(p.phase);
        b.setChallengeKey(p.challengeKey);
        b.setGuidanceKey(p.guidanceKey);
        b.setReason(p.reason);
        b.setMock(p.mock);
        b.setLimited(p.limited);
        return b.build();
    }

    @Override
    public void start(@NonNull String workflow, @NonNull LivenessPigeon.Result<String> result) {
        worker.execute(() -> {
            try {
                result.success(controller().start(workflow));
            } catch (Exception e) {
                result.error(e);
            }
        });
    }

    @NonNull
    @Override
    public LivenessPigeon.LivenessProgressDto progress(@NonNull String sessionId) {
        return toDto(controller().progress(sessionId));
    }

    @Override
    public void checkCapture(@NonNull String sessionId, @NonNull byte[] capturedImage, @NonNull Long captureTimeoutMs,
                             @NonNull LivenessPigeon.Result<Boolean> result) {
        worker.execute(() -> {
            try {
                result.success(controller().checkCapture(sessionId, capturedImage, captureTimeoutMs));
            } catch (Exception e) {
                result.error(e);
            }
        });
    }

    @Override
    public void abort(@NonNull String sessionId) {
        controller().abort(sessionId);
    }

    /**
     * The gate every resident face capture must pass before anything is stored. A LIVE verdict is used up by one capture,
     * so one live check never covers a second capture. False when there is no live session, or the capture is not bound.
     */
    public boolean consumeLiveAndBind(byte[] capturedImage, long captureTimeoutMs) {
        return liveGate.allowStore(id -> {
            AndroidLivenessController c;
            synchronized (this) {
                c = controller;
            }
            if (c == null) {
                return false;
            }
            boolean bound = c.checkCapture(id, capturedImage, captureTimeoutMs);
            c.abort(id);
            return bound;
        });
    }

    private synchronized AndroidLivenessController controller() {
        if (controller == null) {
            throw new IllegalStateException("liveness bridge not attached");
        }
        return controller;
    }
}
