import fp from 'fastify-plugin';
import type { FastifyError, FastifyInstance, FastifyReply, FastifyRequest } from 'fastify';
import { ZodError } from 'zod';

export const errorHandlerPlugin = fp(async (app: FastifyInstance) => {
  app.setErrorHandler((err: FastifyError, req: FastifyRequest, reply: FastifyReply) => {
    if (err instanceof ZodError) {
      req.log.warn({ err }, 'validation error');
      return reply.status(400).send({
        error: 'validation_error',
        message: 'Request failed validation',
        issues: err.issues,
      });
    }

    const status = err.statusCode ?? 500;
    if (status >= 500) {
      req.log.error({ err }, 'server error');
    } else {
      req.log.warn({ err }, 'client error');
    }

    return reply.status(status).send({
      error: err.code ?? 'internal_error',
      message: status >= 500 ? 'Internal server error' : err.message,
    });
  });
});
