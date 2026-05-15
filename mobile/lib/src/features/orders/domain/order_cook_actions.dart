/// Acciones del cocinero según estado y tipo de entrega del pedido.
class CookOrderAction {
  const CookOrderAction(this.action, this.label);
  final String action;
  final String label;
}

bool orderFulfillmentIsDelivery(String fulfillmentType) {
  return fulfillmentType.toUpperCase() == 'DELIVERY';
}

List<CookOrderAction> cookActionsForOrder({
  required String status,
  required String fulfillmentType,
}) {
  final s = status.toUpperCase();
  final delivery = orderFulfillmentIsDelivery(fulfillmentType);

  switch (s) {
    case 'INIT':
      return const [CookOrderAction('CONFIRM', 'Confirmar pedido')];
    case 'CONFIRMED':
      return const [CookOrderAction('START_PREPARING', 'Empezar preparación')];
    case 'PREPARING':
      if (delivery) {
        return const [
          CookOrderAction('MARK_READY_DISPATCH', 'Listo para enviar'),
        ];
      }
      return const [CookOrderAction('MARK_READY_PICKUP', 'Listo para recoger')];
    case 'READY_FOR_PICKUP':
      return const [CookOrderAction('MARK_PICKED_UP', 'Marcar recogido')];
    case 'READY_FOR_DISPATCH':
      return const [
        CookOrderAction('MARK_OUT_FOR_DELIVERY', 'En camino al cliente'),
      ];
    case 'OUT_FOR_DELIVERY':
      return const [CookOrderAction('MARK_DELIVERED', 'Marcar entregado')];
    default:
      return const [];
  }
}
