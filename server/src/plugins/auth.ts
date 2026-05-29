import fp from 'fastify-plugin';
import type { FastifyInstance, FastifyRequest } from 'fastify';

/**
 * JWT authentication plugin.
 *
 * Phase 0: scaffolded but stubbed.
 *   - Decorates Fastify with `authenticate` and `request.user`.
 *   - Throws 501 Not Implemented when invoked, so any route that wires this in
 *     fails loudly until Phase 1 hooks it up to Supabase JWKS.
 *
 * Phase 1 (planned):
 *   - Fetch JWKS from `${SUPABASE_PROJECT_URL}/auth/v1/.well-known/jwks.json`
 *     via `jwks-rsa`, cache the keys, verify the RS256 JWT, populate
 *     `request.user` from the `sub` and `email` claims.
 */

export interface AuthUser {
  id: string;
  email: string;
}

declare module 'fastify' {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest) => Promise<void>;
  }
  interface FastifyRequest {
    user?: AuthUser;
  }
}

export const authPlugin = fp(async (app: FastifyInstance) => {
  app.decorate('authenticate', async (_req: FastifyRequest) => {
    const err = new Error('auth not yet wired — Phase 1') as Error & {
      statusCode: number;
      code: string;
    };
    err.statusCode = 501;
    err.code = 'not_implemented';
    throw err;
  });
});
