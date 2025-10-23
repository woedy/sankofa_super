import 'package:intl/intl.dart';
import 'package:sankofasave/models/transaction_model.dart';

class CashflowExportService {
  final DateFormat _timestampFormatter = DateFormat('yyyy-MM-dd HH:mm');
  final DateFormat _filenameFormatter = DateFormat('yyyyMMdd_HHmm');

  String generateFilename() {
    final now = DateTime.now();
    return 'sankofa_cashflow_${_filenameFormatter.format(now)}.csv';
  }

  Future<String> buildCsv(List<TransactionModel> transactions) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'receipt_id,type,status,amount,fee,channel,counterparty,description,created_at,updated_at',
    );

    for (final transaction in transactions) {
      final receipt = _sanitize(transaction.reference ?? transaction.id);
      final type = _sanitize(transaction.type);
      final status = _sanitize(transaction.status);
      final amount = transaction.amount.toStringAsFixed(2);
      final fee = transaction.fee?.toStringAsFixed(2) ?? '0.00';
      final channel = _sanitize(transaction.channel ?? '');
      final counterparty = _sanitize(transaction.counterparty ?? '');
      final description = _sanitize(transaction.description);
      final created = _timestampFormatter.format(transaction.createdAt);
      final updated = _timestampFormatter.format(transaction.updatedAt);

      buffer.writeln(
        '$receipt,$type,$status,$amount,$fee,$channel,$counterparty,$description,$created,$updated',
      );
    }

    return buffer.toString();
  }

  String _sanitize(String value) {
    if (value.contains(',') || value.contains('"')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
