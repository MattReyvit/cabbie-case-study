// Cabbie — booking input validation (sanitized for public case study)
// Runs server-side before any write reaches the database.
// Real logic, anonymized. No credentials, no endpoints, no client data.

import { z } from "zod";

const bookingSchema = z.object({
  passengerName: z.string().trim().min(2).max(120),
  origin: z.string().trim().min(3).max(200),
  destination: z.string().trim().min(3).max(200),
  scheduledAt: z.coerce.date().refine((d) => d.getTime() > Date.now(), {
    message: "Pickup time must be in the future",
  }),
  seats: z.number().int().min(1).max(8),
});

export type BookingInput = z.infer<typeof bookingSchema>;

type ValidationResult =
  | { ok: true; data: BookingInput }
  | { ok: false; errors: string[] };

/**
 * Validates a booking request before it is assigned to a driver.
 * Returns typed data on success, or a flat list of human-readable errors.
 */
export function validateBooking(raw: unknown): ValidationResult {
  const parsed = bookingSchema.safeParse(raw);
  if (!parsed.success) {
    return {
      ok: false,
      errors: parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`),
    };
  }
  return { ok: true, data: parsed.data };
}

/**
 * Allowed status transitions — guards against invalid jumps
 * (e.g. a cancelled booking can never go back to in_progress).
 */
const transitions: Record<string, string[]> = {
  requested: ["assigned", "cancelled"],
  assigned: ["in_progress", "cancelled"],
  in_progress: ["completed", "cancelled"],
  completed: [],
  cancelled: [],
};

export function canTransition(from: string, to: string): boolean {
  return transitions[from]?.includes(to) ?? false;
}
