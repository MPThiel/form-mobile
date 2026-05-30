import fp from 'fastify-plugin';
import {
  createRemoteJWKSet,
  jwtVerify,
  errors as joseErrors,
  type JWTVerifyGetKey,
} from 'jose';
import type { FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';

/**
 * Supabase JWT authentication.
 *
 * Verifies the incoming `Authorization: Bearer <jwt>` against Supabase's public
 * JWKS endpoint (`${SUPABASE_PROJECT_URL}/auth/v1/.well-known/jwks.json`).
 * Checks signature, issuer, audience and expiry. On success it attaches the
 * `sub` (Supabase user id) and `email` claims to `request.user`.
 *
 * The JWKS resolver is built lazily on the first authenticated request — jose
 * fetches the key set on demand and caches it for `SUPABASE_JWKS_CACHE_TTL_SECONDS`
 * — so the app still boots in environments without the Supabase env set or
 * without network (e.g. CI smoke tests that only hit /health).
 */

export interface AuthUser {
  /** Supabase user id (JWT `sub`). Also used as our `User.id`. */
  id: string;
  email: string;
}

export interface AuthPluginOptions {
  /**
   * Override the JWKS key resolver. Production leaves this undefined and a
   * remote resolver is built from SUPABASE_PROJECT_URL. Tests inject a local
   * key set so verification works offline.
   */
  getKey?: JWTVerifyGetKey;
}

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<void>;
  }
  interface FastifyRequest {
    user?: AuthUser;
  }
}

class AuthError extends Error {
  readonly statusCode = 401;
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'AuthError';
  }
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} must be set for JWT authentication`);
  }
  return value;
}

export const authPlugin = fp<AuthPluginOptions>(async (app: FastifyInstance, opts) => {
  const audience = process.env.SUPABASE_AUDIENCE ?? 'authenticated';

  let getKey = opts.getKey;
  let issuer = process.env.SUPABASE_ISSUER;

  // Built on first use, then memoised. Throws (→ 500) if the server is
  // misconfigured, which is the correct signal for an operator.
  function resolveKeyGetter(): JWTVerifyGetKey {
    if (getKey) return getKey;
    const projectUrl = requireEnv('SUPABASE_PROJECT_URL').replace(/\/+$/, '');
    issuer ??= `${projectUrl}/auth/v1`;
    const ttlSeconds = Number(process.env.SUPABASE_JWKS_CACHE_TTL_SECONDS ?? 3600);
    const jwksUrl = new URL(`${projectUrl}/auth/v1/.well-known/jwks.json`);
    getKey = createRemoteJWKSet(jwksUrl, { cacheMaxAge: ttlSeconds * 1000 });
    return getKey;
  }

  app.decorate('authenticate', async (req: FastifyRequest, _reply: FastifyReply) => {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw new AuthError('missing_token', 'Missing or malformed Authorization header');
    }
    const token = header.slice('Bearer '.length).trim();
    if (!token) {
      throw new AuthError('missing_token', 'Empty bearer token');
    }

    // Build the resolver only once we actually have a token to verify, so an
    // unauthenticated request fails fast with 401 rather than a config 500.
    const keyGetter = resolveKeyGetter();

    let payload;
    try {
      ({ payload } = await jwtVerify(token, keyGetter, {
        audience,
        ...(issuer ? { issuer } : {}),
      }));
    } catch (err) {
      if (err instanceof joseErrors.JWTExpired) {
        throw new AuthError('token_expired', 'Access token has expired');
      }
      req.log.warn({ err }, 'jwt verification failed');
      throw new AuthError('invalid_token', 'Access token verification failed');
    }

    if (!payload.sub) {
      throw new AuthError('invalid_token', 'Token is missing the subject claim');
    }
    const email = typeof payload.email === 'string' ? payload.email : undefined;
    if (!email) {
      throw new AuthError('email_missing', 'Token is missing an email claim');
    }

    req.user = { id: payload.sub, email };
  });
});
