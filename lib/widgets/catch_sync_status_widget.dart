import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';

class CatchSyncStatusWidget extends StatefulWidget {
  final String catchId;
  final String initialStatus;

  const CatchSyncStatusWidget({
    Key? key,
    required this.catchId,
    this.initialStatus = 'synced',
  }) : super(key: key);

  @override
  _CatchSyncStatusWidgetState createState() => _CatchSyncStatusWidgetState();
}

class _CatchSyncStatusWidgetState extends State<CatchSyncStatusWidget> {
  String status = 'synced';
  Map<String, dynamic>? pendingDetails;

  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
    _checkSyncStatus();
  }

  Future<void> _checkSyncStatus() async {
    final isPending = await OfflineSyncService.isCatchPending(widget.catchId);
    
    if (isPending) {
      final details = await OfflineSyncService.getPendingCatchDetails(widget.catchId);
      if (mounted) {
        setState(() {
          status = 'pending';
          pendingDetails = details;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildStatusChip();
  }

  Widget _buildStatusChip() {
    switch (status) {
      case 'synced':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done, size: 14, color: Colors.green.shade700),
              SizedBox(width: 4),
              Text(
                'Terkirim',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        );

      case 'pending':
        return GestureDetector(
          onTap: () => _showPendingDetails(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.orange.shade700),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'Menunggu',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                Icon(Icons.info_outline, size: 12, color: Colors.orange.shade700),
              ],
            ),
          ),
        );

      case 'failed':
        return GestureDetector(
          onTap: () => _showFailedDetails(),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade700),
                SizedBox(width: 4),
                Text(
                  'Gagal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }

  void _showPendingDetails() {
    if (pendingDetails == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.orange),
            SizedBox(width: 8),
            Text('Status Pengiriman'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data ini sedang menunggu untuk dikirim ke server.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detail:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Percobaan: ${pendingDetails!['retry_count']} kali'),
                  Text('Dibuat: ${_formatDate(pendingDetails!['created_at'])}'),
                  if (pendingDetails!['last_error'] != null)
                    Text('Error: ${pendingDetails!['last_error']}'),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '💡 Data akan dikirim otomatis saat koneksi internet stabil.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showFailedDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Pengiriman Gagal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data ini gagal dikirim ke server setelah beberapa percobaan.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '🔄 Sistem akan terus mencoba mengirim data ini secara otomatis.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}