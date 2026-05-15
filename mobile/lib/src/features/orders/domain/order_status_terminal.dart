/// Whether an order is finished for UI lists (no longer needs active tracking).
bool orderStatusIsTerminal(String raw) {
  final s = raw.toUpperCase();
  if (s == 'DELIVERED' || s == 'PICKED_UP' || s == 'REFUNDED') return true;
  if (s.startsWith('CANCELLED')) return true;
  return false;
}

/// Estado esperado tras una acción del cocinero (UI optimista).
String? statusAfterCookAction(String action) {
  switch (action) {
    case 'CONFIRM':
      return 'CONFIRMED';
    case 'START_PREPARING':
      return 'PREPARING';
    case 'MARK_READY_PICKUP':
      return 'READY_FOR_PICKUP';
    case 'MARK_READY_DISPATCH':
      return 'READY_FOR_DISPATCH';
    case 'MARK_OUT_FOR_DELIVERY':
      return 'OUT_FOR_DELIVERY';
    case 'MARK_DELIVERED':
      return 'DELIVERED';
    case 'MARK_PICKED_UP':
      return 'PICKED_UP';
    default:
      return null;
  }
}
