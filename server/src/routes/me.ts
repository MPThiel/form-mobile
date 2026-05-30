import type { FastifyInstance } from 'fastify';

/**
 * Current-user routes.
 *
 *  - GET  /me  → the signed-in user's Profile. 404 until onboarding (Phase 2)
 *                populates it.
 *  - POST /me  → idempotently provision the User account row on first sign-in.
 *                Returns the account and its Profile (null until onboarding).
 *
 * The Profile model's onboarding fields are required and have no defaults, so a
 * Profile row is intentionally NOT created here — that happens during the
 * Phase 2 onboarding wizard. We key User.id on the Supabase user id (JWT `sub`)
 * so auth identity and our primary key stay aligned.
 */
export async function meRoutes(app: FastifyInstance): Promise<void> {
  app.get('/me', { preHandler: app.authenticate }, async (req, reply) => {
    const user = req.user;
    if (!user) {
      // Unreachable after `authenticate`, but keeps the type narrowed.
      return reply.status(401).send({ error: 'unauthenticated', message: 'Not authenticated' });
    }

    const profile = await app.prisma.profile.findUnique({ where: { userId: user.id } });
    if (!profile) {
      return reply
        .status(404)
        .send({ error: 'profile_not_found', message: 'No profile yet — complete onboarding.' });
    }
    return profile;
  });

  app.post('/me', { preHandler: app.authenticate }, async (req, reply) => {
    const user = req.user;
    if (!user) {
      return reply.status(401).send({ error: 'unauthenticated', message: 'Not authenticated' });
    }

    const account = await app.prisma.user.upsert({
      where: { id: user.id },
      update: { email: user.email },
      create: { id: user.id, email: user.email, authProvider: 'email' },
      include: { profile: true },
    });

    return {
      user: {
        id: account.id,
        email: account.email,
        authProvider: account.authProvider,
        subscriptionTier: account.subscriptionTier,
        createdAt: account.createdAt,
      },
      profile: account.profile,
    };
  });
}
