import 'order_cook_actions.dart';

/// Progreso del pedido para la UI del cliente (barra continua, sin reinicios).
class OrderTrackingSnapshot {
  const OrderTrackingSnapshot({
    required this.progress,
    required this.currentStepLabel,
    required this.stepIndex,
    required this.stepCount,
  });

  /// 0.0 … 1.0
  final double progress;
  final String currentStepLabel;
  final int stepIndex;
  final int stepCount;
}

OrderTrackingSnapshot orderTrackingSnapshot({
  required String status,
  required String fulfillmentType,
}) {
  final s = status.toUpperCase();
  final delivery = orderFulfillmentIsDelivery(fulfillmentType);

  if (delivery) {
    const steps = <(String, double, String)>[
      ('INIT', 0.10, 'Pedido recibido'),
      ('CONFIRMED', 0.28, 'Confirmado'),
      ('PREPARING', 0.48, 'En preparación'),
      ('READY_FOR_DISPATCH', 0.68, 'Listo para enviar'),
      ('OUT_FOR_DELIVERY', 0.86, 'En camino'),
      ('DELIVERED', 1.0, 'Entregado'),
    ];
    return _fromSteps(s, steps);
  }

  const steps = <(String, double, String)>[
    ('INIT', 0.10, 'Pedido recibido'),
    ('CONFIRMED', 0.28, 'Confirmado'),
    ('PREPARING', 0.48, 'En preparación'),
    ('READY_FOR_PICKUP', 0.72, 'Listo para recoger'),
    ('PICKED_UP', 1.0, 'Entregado'),
  ];
  return _fromSteps(s, steps);
}

OrderTrackingSnapshot _fromSteps(
  String status,
  List<(String, double, String)> steps,
) {
  var match = steps.first;
  var idx = 0;
  for (var i = 0; i < steps.length; i++) {
    if (status == steps[i].$1) {
      match = steps[i];
      idx = i;
      break;
    }
    if (_statusRank(status) > _statusRank(steps[i].$1)) {
      match = steps[i];
      idx = i;
    }
  }

  if (status.startsWith('CANCELLED')) {
    return OrderTrackingSnapshot(
      progress: 0,
      currentStepLabel: 'Cancelado',
      stepIndex: 0,
      stepCount: steps.length,
    );
  }

  return OrderTrackingSnapshot(
    progress: match.$2,
    currentStepLabel: match.$3,
    stepIndex: idx,
    stepCount: steps.length,
  );
}

int _statusRank(String s) {
  const order = [
    'INIT',
    'CONFIRMED',
    'PREPARING',
    'READY_FOR_PICKUP',
    'READY_FOR_DISPATCH',
    'OUT_FOR_DELIVERY',
    'PICKED_UP',
    'DELIVERED',
  ];
  final i = order.indexOf(s);
  return i < 0 ? 0 : i;
}
