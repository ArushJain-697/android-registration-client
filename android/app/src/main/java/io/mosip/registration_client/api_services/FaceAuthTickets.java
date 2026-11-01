package io.mosip.registration_client.api_services;

import io.sajeev.session.FaceAuthTicket;

/** The one ticket holder of the app. Only the face-capture code in Java grants; the login and approval code spends. */
public final class FaceAuthTickets {
    public static final FaceAuthTicket INSTANCE = new FaceAuthTicket(System::currentTimeMillis, 60_000L);

    private FaceAuthTickets() {
    }
}
