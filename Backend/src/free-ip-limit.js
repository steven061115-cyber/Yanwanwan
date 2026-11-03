// Free-tier extractions are counted per install ID, and the app lets users reset that ID.
// This second, per-IP daily cap stops a reset from handing out a fresh free quota each time.
// Counts live in memory, so a restart clears them; that is acceptable for an abuse cap.
export class FreeIPDailyLimiter {
  constructor(limit) {
    this.limit = limit;
    this.date = null;
    this.counts = new Map();
  }

  // Takes one slot for this IP today. Returns false when the IP has used them all.
  reserve(ip, date) {
    this.#rollover(date);
    const used = this.counts.get(ip) ?? 0;
    if (used >= this.limit) return false;
    this.counts.set(ip, used + 1);
    return true;
  }

  // Gives a slot back when the extraction failed and the user was not charged.
  release(ip, date) {
    if (this.date !== date) return;
    const used = this.counts.get(ip) ?? 0;
    if (used <= 1) {
      this.counts.delete(ip);
    } else {
      this.counts.set(ip, used - 1);
    }
  }

  #rollover(date) {
    if (this.date === date) return;
    this.date = date;
    this.counts.clear();
  }
}
