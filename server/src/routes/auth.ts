import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { RateLimiter } from '../lib/rateLimiter.js';

/**
 * Pre-auth endpoints (no JWT required).
 *
 * POST /auth/magic-link proxies the Supabase "send magic link" request through
 * our backend, so the Flutter client never has to resolve the Supabase domain
 * directly (it fails to resolve on some networks). Only the SEND step is
 * proxied — the magic-link callback is still handled on-device by
 * supabase_flutter via the deep link.
 */

const MagicLinkBody = z.object({
  email: z.string().email(),
  redirectTo: z.string().url(),
});

// Max 3 magic-link requests per email per 15 minutes.
const magicLinkLimiter = new RateLimiter(3, 15 * 60 * 1000);

export async function authRoutes(app: FastifyInstance): Promise<void> {
  app.post('/auth/magic-link', async (req, reply) => {
    const { email, redirectTo } = MagicLinkBody.parse(req.body);
    const normalizedEmail = email.trim().toLowerCase();

    if (!magicLinkLimiter.check(normalizedEmail)) {
      return reply.status(429).send({
        error: 'rate_limited',
        message: 'Too many magic-link requests. Please wait a few minutes and try again.',
      });
    }

    const projectUrl = process.env.SUPABASE_PROJECT_URL?.replace(/\/+$/, '');
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!projectUrl || !serviceRoleKey) {
      req.log.error(
        'magic-link: SUPABASE_PROJECT_URL or SUPABASE_SERVICE_ROLE_KEY is not set',
      );
      return reply.status(500).send({
        error: 'auth_unconfigured',
        message: 'Magic-link sending is not configured.',
      });
    }

    // Mirrors supabase-js signInWithOtp: POST /auth/v1/otp with redirect_to as a
    // query param. Authenticated with the service_role key server-side only.
    const url = `${projectUrl}/auth/v1/otp?redirect_to=${encodeURIComponent(redirectTo)}`;

    let res: Response;
    try {
      res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
        },
        body: JSON.stringify({ email: normalizedEmail, create_user: true }),
      });
    } catch (err) {
      req.log.error({ err }, 'magic-link: request to Supabase failed');
      return reply.status(502).send({
        error: 'auth_provider_unreachable',
        message: 'Could not reach the auth provider. Please try again.',
      });
    }

    if (!res.ok) {
      const detail = await res.text().catch(() => '');
      req.log.warn(
        { status: res.status, detail },
        'magic-link: Supabase returned an error',
      );
      // Supabase enforces its own per-email throttle (429); surface it as such.
      if (res.status === 429) {
        return reply.status(429).send({
          error: 'rate_limited',
          message: 'Too many requests. Please wait a moment and try again.',
        });
      }
      return reply.status(502).send({
        error: 'auth_provider_error',
        message: 'Could not send the magic link. Please try again.',
      });
    }

    return { success: true };
  });
}
