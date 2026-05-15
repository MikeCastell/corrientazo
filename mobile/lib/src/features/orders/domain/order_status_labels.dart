String orderStatusLabel(String raw) {
  switch (raw.toUpperCase()) {
    case 'INIT':
      return 'Nuevo';
    case 'CONFIRMED':
      return 'Confirmado';
    case 'PREPARING':
      return 'Preparando';
    case 'READY_FOR_PICKUP':
      return 'Listo para recoger';
    case 'READY_FOR_DISPATCH':
      return 'Listo para enviar';
    case 'OUT_FOR_DELIVERY':
      return 'En camino';
    case 'DELIVERED':
    case 'PICKED_UP':
      return 'Entregado';
    case 'CANCELLED_BY_CLIENT':
      return 'Cancelado por ti';
    case 'CANCELLED_BY_COOK':
      return 'Cancelado por el cook';
    case 'CANCELLED_BY_ADMIN':
      return 'Pedido cancelado';
    default:
      if (raw.toUpperCase().startsWith('CANCELLED')) return 'Cancelado';
      return raw;
  }
}

String orderPseudoEtaLabel(DateTime createdAt, String status) {
  final s = status.toUpperCase();
  if (s.startsWith('CANCELLED')) return 'Pedido cerrado';
  final mins = DateTime.now().difference(createdAt).inMinutes.abs();
  if (s == 'READY_FOR_PICKUP' ||
      s == 'READY_FOR_DISPATCH' ||
      s == 'PICKED_UP' ||
      s == 'DELIVERED') {
    return 'Listo';
  }
  final low = 15 + (mins % 8);
  final high = low + 12;
  return '$low–$high min';
}
