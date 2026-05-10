import '../../orders/domain/order_summary.dart';
import '../../orders/domain/order_status_terminal.dart';

/// Estados finales (no cuentan como “activos” en operación).
bool cookOrderIsTerminal(String raw) => orderStatusIsTerminal(raw);

bool cookOrderIsActive(OrderSummary o) => !cookOrderIsTerminal(o.status);

bool cookOrderIsSuccessfulCompletion(String raw) {
  final s = raw.toUpperCase();
  return s == 'DELIVERED' || s == 'PICKED_UP';
}

bool sameLocalCalendarDay(DateTime instant, DateTime referenceLocal) {
  final a = instant.toLocal();
  final b = referenceLocal;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Pedidos que ven cocina en “operación de hoy”: todos los activos + los cerrados con éxito hoy (fecha local).
bool cookOrderShowsInOperacionDeHoy(OrderSummary o, DateTime nowLocal) {
  if (!cookOrderIsTerminal(o.status)) return true;
  if (!cookOrderIsSuccessfulCompletion(o.status)) return false;
  final t = o.updatedAt ?? o.createdAt;
  return sameLocalCalendarDay(t, nowLocal);
}

int countCookOrdersCreatedToday(List<OrderSummary> orders, DateTime nowLocal) {
  return orders.where((o) => sameLocalCalendarDay(o.createdAt, nowLocal)).length;
}

int countCookOrdersCompletedSuccessfulToday(
  List<OrderSummary> orders,
  DateTime nowLocal,
) {
  return orders.where((o) {
    if (!cookOrderIsSuccessfulCompletion(o.status)) return false;
    final t = o.updatedAt ?? o.createdAt;
    return sameLocalCalendarDay(t, nowLocal);
  }).length;
}
