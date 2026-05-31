import { describe, it, expect, beforeAll, afterAll, beforeEach, afterEach, vi } from 'vitest';
import { buildApp } from '../src/app.js';
import type { FastifyInstance } from 'fastify';

const REDIRECT = 'form://login-callback';

describe('POST /auth/magic-link', () => {
  let app: FastifyInstance;
  let fetchMock: ReturnType<typeof vi.fn>;

  beforeAll(async () => {
    process.env.SUPABASE_PROJECT_URL = 'https://test-project.supabase.co';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'service-role-secret';
    app = await buildApp();
    await app.ready();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    fetchMock = vi.fn();
    vi.stubGlobal('fetch', fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  function send(email: string) {
    return app.inject({
      method: 'POST',
      url: '/auth/magic-link',
      payload: { email, redirectTo: REDIRECT },
    });
  }

  it('400 on an invalid email', async () => {
    const res = await send('not-an-email');
    expect(res.statusCode).toBe(400);
    expect(res.json().error).toBe('validation_error');
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('400 when redirectTo is missing', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/auth/magic-link',
      payload: { email: 'a@b.com' },
    });
    expect(res.statusCode).toBe(400);
  });

  it('calls the Supabase OTP endpoint and returns { success: true }', async () => {
    fetchMock.mockResolvedValue(new Response('{}', { status: 200 }));

    const res = await send('Happy@Example.com');

    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({ success: true });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [calledUrl, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(calledUrl).toBe(
      `https://test-project.supabase.co/auth/v1/otp?redirect_to=${encodeURIComponent(REDIRECT)}`,
    );
    const headers = init.headers as Record<string, string>;
    expect(headers.apikey).toBe('service-role-secret');
    expect(headers.Authorization).toBe('Bearer service-role-secret');
    // Email is normalised (trimmed + lowercased).
    expect(JSON.parse(init.body as string)).toEqual({
      email: 'happy@example.com',
      create_user: true,
    });
  });

  it('rate-limits a single email to 3 requests, then 429s', async () => {
    fetchMock.mockResolvedValue(new Response('{}', { status: 200 }));
    const email = 'limited@example.com';

    for (let i = 0; i < 3; i++) {
      const ok = await send(email);
      expect(ok.statusCode).toBe(200);
    }

    const blocked = await send(email);
    expect(blocked.statusCode).toBe(429);
    expect(blocked.json().error).toBe('rate_limited');
    // The 4th request must not reach Supabase.
    expect(fetchMock).toHaveBeenCalledTimes(3);
  });

  it('maps a Supabase 429 to a 429 rate_limited response', async () => {
    fetchMock.mockResolvedValue(new Response('rate limit', { status: 429 }));
    const res = await send('throttled@example.com');
    expect(res.statusCode).toBe(429);
    expect(res.json().error).toBe('rate_limited');
  });

  it('maps other Supabase errors to a 502', async () => {
    fetchMock.mockResolvedValue(new Response('boom', { status: 500 }));
    const res = await send('errors@example.com');
    expect(res.statusCode).toBe(502);
    expect(res.json().error).toBe('auth_provider_error');
  });

  it('502 when Supabase is unreachable', async () => {
    fetchMock.mockRejectedValue(new Error('ENOTFOUND'));
    const res = await send('unreachable@example.com');
    expect(res.statusCode).toBe(502);
    expect(res.json().error).toBe('auth_provider_unreachable');
  });
});
