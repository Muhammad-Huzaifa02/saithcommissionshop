import 'package:cloud_firestore/cloud_firestore.dart';

class ReminderLog {
  final String   id;
  final String   customerId;
  final String   customerName;
  final String   customerPhone;
  final double   pendingAmount;
  final String   channel;      // 'whatsapp' | 'sms' | 'call'
  final String   status;       // 'sent' | 'failed' | 'seen' | 'paid'
  final String   message;
  final String   sentBy;
  final DateTime sentAt;

  ReminderLog({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pendingAmount,
    required this.channel,
    required this.status,
    required this.message,
    required this.sentBy,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() => {
    'customer_id':    customerId,
    'customer_name':  customerName,
    'customer_phone': customerPhone,
    'pending_amount': pendingAmount,
    'channel':        channel,
    'status':         status,
    'message':        message,
    'sent_by':        sentBy,
    'sent_at':        Timestamp.fromDate(sentAt),
  };

  factory ReminderLog.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReminderLog(
      id:            doc.id,
      customerId:    d['customer_id']    ?? '',
      customerName:  d['customer_name']  ?? '',
      customerPhone: d['customer_phone'] ?? '',
      pendingAmount: (d['pending_amount'] as num? ?? 0).toDouble(),
      channel:       d['channel']        ?? 'whatsapp',
      status:        d['status']         ?? 'sent',
      message:       d['message']        ?? '',
      sentBy:        d['sent_by']        ?? '',
      sentAt:        (d['sent_at'] as Timestamp).toDate(),
    );
  }
}
