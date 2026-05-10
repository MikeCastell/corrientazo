/// Whether an order is finished for UI lists (no longer needs active tracking).
bool orderStatusIsTerminal(String raw) {
  final s = raw.toUpperCase();
  if (s == 'DELIVERED' || s == 'PICKED_UP' || s == 'REFUNDED') return true;
  if (s.startsWith('CANCELLED')) return true;
  return false;
}
