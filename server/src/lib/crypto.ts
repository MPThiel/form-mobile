/**
 * Token encryption helpers for Strava access/refresh tokens at rest.
 *
 * Phase 0: stubbed. Real implementation in Phase 7.
 *  - AES-256-GCM with key from STRAVA_TOKEN_ENCRYPTION_KEY (base64-encoded 32 bytes).
 *  - Returns a versioned ciphertext string we can rotate.
 */
