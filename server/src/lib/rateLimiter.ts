/**
 * Tiny in-memory fixed-window rate limiter keyed by an arbitrary string.
 *
 * Suitable for a single Railway instance during beta: state lives in process
 * memory, so it resets on restart and is NOT shared across instances. If we
 * scale horizontally, swap this for a Redis-backed limiter.
 */
export class RateLimiter {
  private readonly hits = new Map<string, number[]>();

  constructor(
    private readonly maxHits: number,
    private readonly windowMs: number,
  ) {}

  /**
   * Records an attempt for `key` and returns whether it is allowed. Rejected
   * attempts (over the limit) are not counted, so the window can recover.
   */
  check(key: string, now: number = Date.now()): boolean {
    const windowStart = now - this.windowMs;
    const recent = (this.hits.get(key) ?? []).filter((t) => t > windowStart);

    if (recent.length >= this.maxHits) {
      this.hits.set(key, recent);
      return false;
    }

    recent.push(now);
    this.hits.set(key, recent);
    return true;
  }

  /** Clears all recorded hits. Used by tests. */
  reset(): void {
    this.hits.clear();
  }
}
