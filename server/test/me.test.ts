import { describe, it, expect, beforeAll, vi } from 'vitest';
import Fastify, { type FastifyInstance } from 'fastify';
import {
  SignJWT,
  exportJWK,
  generateKeyPair,
  createLocalJWKSet,
  type JWTVerifyGetKey,
} from 'jose';
import type { PrismaClient } from '@prisma/client';
import { errorHandlerPlugin } from '../src/plugins/errorHandler.js';
import { authPlugin } from '../src/plugins/auth.js';
import { meRoutes } from '../src/routes/me.js';

const KID = 'test-key';
const AUDIENCE = 'authenticated';

let privateKey: Awaited<ReturnType<typeof generateKeyPair>>['privateKey'];
let localJwks: JWTVerifyGetKey;

beforeAll(async () => {
  const { publicKey, privateKey: pk } = await generateKeyPair('RS256');
  privateKey = pk;
  const publicJwk = await exportJWK(publicKey);
  publicJwk.kid = KID;
  publicJwk.alg = 'RS256';
  publicJwk.use = 'sig';
  localJwks = createLocalJWKSet({ keys: [publicJwk] });
});

async function signToken(opts: {
  sub?: string;
  email?: string | null;
  audience?: string;
  expired?: boolean;
}): Promise<string> {
  const builder = new SignJWT({ ...(opts.email !== null ? { email: opts.email } : {}) })
    .setProtectedHeader({ alg: 'RS256', kid: KID })
    .setIssuedAt()
    .setAudience(opts.audience ?? AUDIENCE);
  if (opts.sub) builder.setSubject(opts.sub);
  builder.setExpirationTime(opts.expired ? '-1h' : '1h');
  return builder.sign(privateKey);
}

/** Minimal app with a fake Prisma and the test JWKS so verification runs offline. */
async function buildTestApp(prisma: Partial<PrismaClient>): Promise<FastifyInstance> {
  const app = Fastify();
  await app.register(errorHandlerPlugin);
  app.decorate('prisma', prisma as PrismaClient);
  await app.register(authPlugin, { getKey: localJwks });
  await app.register(meRoutes);
  await app.ready();
  return app;
}

describe('auth boundary on /me', () => {
  it('401 missing_token when no Authorization header', async () => {
    const app = await buildTestApp({});
    const res = await app.inject({ method: 'POST', url: '/me' });
    expect(res.statusCode).toBe(401);
    expect(res.json().error).toBe('missing_token');
    await app.close();
  });

  it('401 invalid_token for a garbage bearer token', async () => {
    const app = await buildTestApp({});
    const res = await app.inject({
      method: 'POST',
      url: '/me',
      headers: { authorization: 'Bearer not-a-real-jwt' },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error).toBe('invalid_token');
    await app.close();
  });

  it('401 token_expired for an expired token', async () => {
    const app = await buildTestApp({});
    const token = await signToken({ sub: 'user-1', email: 'a@b.com', expired: true });
    const res = await app.inject({
      method: 'POST',
      url: '/me',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error).toBe('token_expired');
    await app.close();
  });

  it('401 invalid_token for the wrong audience', async () => {
    const app = await buildTestApp({});
    const token = await signToken({ sub: 'user-1', email: 'a@b.com', audience: 'other' });
    const res = await app.inject({
      method: 'POST',
      url: '/me',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error).toBe('invalid_token');
    await app.close();
  });

  it('401 email_missing when the token has no email claim', async () => {
    const app = await buildTestApp({});
    const token = await signToken({ sub: 'user-1', email: null });
    const res = await app.inject({
      method: 'POST',
      url: '/me',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().error).toBe('email_missing');
    await app.close();
  });
});

describe('POST /me', () => {
  it('upserts the User row keyed on the token sub and returns the account', async () => {
    const upsert = vi.fn().mockResolvedValue({
      id: 'user-uuid',
      email: 'a@b.com',
      authProvider: 'email',
      subscriptionTier: 'free',
      createdAt: new Date('2026-01-01T00:00:00Z'),
      profile: null,
    });
    const app = await buildTestApp({ user: { upsert } } as unknown as Partial<PrismaClient>);
    const token = await signToken({ sub: 'user-uuid', email: 'a@b.com' });

    const res = await app.inject({
      method: 'POST',
      url: '/me',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(200);
    expect(upsert).toHaveBeenCalledWith({
      where: { id: 'user-uuid' },
      update: { email: 'a@b.com' },
      create: { id: 'user-uuid', email: 'a@b.com', authProvider: 'email' },
      include: { profile: true },
    });
    const body = res.json();
    expect(body.user.id).toBe('user-uuid');
    expect(body.profile).toBeNull();
    await app.close();
  });
});

describe('GET /me', () => {
  it('404 profile_not_found before onboarding', async () => {
    const findUnique = vi.fn().mockResolvedValue(null);
    const app = await buildTestApp({
      profile: { findUnique },
    } as unknown as Partial<PrismaClient>);
    const token = await signToken({ sub: 'user-uuid', email: 'a@b.com' });

    const res = await app.inject({
      method: 'GET',
      url: '/me',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(404);
    expect(res.json().error).toBe('profile_not_found');
    expect(findUnique).toHaveBeenCalledWith({ where: { userId: 'user-uuid' } });
    await app.close();
  });

  it('returns the Profile when one exists', async () => {
    const profile = { userId: 'user-uuid', age: 30, currentWeight: 80 };
    const findUnique = vi.fn().mockResolvedValue(profile);
    const app = await buildTestApp({
      profile: { findUnique },
    } as unknown as Partial<PrismaClient>);
    const token = await signToken({ sub: 'user-uuid', email: 'a@b.com' });

    const res = await app.inject({
      method: 'GET',
      url: '/me',
      headers: { authorization: `Bearer ${token}` },
    });

    expect(res.statusCode).toBe(200);
    expect(res.json()).toMatchObject({ userId: 'user-uuid', age: 30 });
    await app.close();
  });
});
