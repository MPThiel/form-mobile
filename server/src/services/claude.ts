/**
 * Anthropic Claude API wrapper.
 *
 * Phase 0: stubbed. Real implementation lands in Phase 4 (Vision) / Phase 5 (chat).
 *
 * Rules from CLAUDE.md:
 *  - Model is always `claude-sonnet-4-20250514`.
 *  - Every call goes through this module — never inline `fetch` to Anthropic elsewhere.
 *  - Chat responses stream via SSE; non-chat calls return whole responses.
 *  - System prompts are built fresh per call by `services/coachPrompt.ts`.
 */

export const CLAUDE_MODEL = 'claude-sonnet-4-20250514';

export const TOKEN_BUDGETS = {
  coachMessage: 500,
  coachBriefing: 200,
  coachWelcome: 250,
  mealsAnalyze: 300,
  planGenerate: 800,
  planAdjust: 400,
} as const;
