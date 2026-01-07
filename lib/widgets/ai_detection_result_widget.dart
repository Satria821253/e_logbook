import 'package:flutter/material.dart';
import 'package:e_logbook/services/gemini_fish_detection_service.dart';

class AIDetectionResultWidget extends StatelessWidget {
  final FishDetectionResult result;
  final VoidCallback onAccept;
  final VoidCallback onRetry;

  const AIDetectionResultWidget({
    super.key,
    required this.result,
    required this.onAccept,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Detection Mode Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/icons/icon_ai.png',
                  width: 24,
                  height: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Detection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getConfidenceLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Detection Source Info (Gemini AI)
          if (result.notes.isNotEmpty) _buildSourceInfoCard(),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Detection Results
          _buildResultRow('🐠 Nama Ikan', result.fishName),
          _buildResultRow('🏷️ Jenis Ikan', result.fishType),
          _buildResultRow(
            '✨ Kondisi Ikan',
            result.condition,
            trailing: _buildConditionIndicator(),
          ),
          _buildResultRow(
            '📏 Est. Panjang Ikan',
            '${result.estimatedLength.toStringAsFixed(1)} cm',
          ),
          _buildResultRow(
            '📐 Est. Tinggi Ikan',
            '${(result.estimatedLength * 0.25).toStringAsFixed(1)} cm',
          ),
          _buildResultRow(
            '⚖️ Est. Berat Per Ikan',
            '${result.unitWeight.toStringAsFixed(2)} kg',
          ),
          _buildResultRow(
            '📊 Est. Berat Total',
            '${result.estimatedWeight.toStringAsFixed(2)} kg',
          ),
          _buildResultRow(
            '🔢 Est. Jumlah Ikan',
            '${result.estimatedQuantity} ekor',
          ),

          const SizedBox(height: 12),

          // Freshness Analysis
          if (result.freshness.isNotEmpty) _buildFreshnessCard(),

          // Notes Card
          if (result.notes.isNotEmpty) _buildNotesCard(),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Deteksi Ulang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Gunakan Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Deteksi AI: Gemini 2.5 Flash',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'GEMINI',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionIndicator() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _getFreshnessColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getFreshnessColor().withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildFreshnessCard() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getFreshnessColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _getFreshnessColor().withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: _getFreshnessColor(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Analisis Kesegaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getFreshnessColor(),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                result.freshness,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    // Parse notes untuk mendapatkan info detail
    final notesLines = result.notes
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Detail Deteksi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...notesLines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line.trim(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    String? subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing,
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor() {
    if (result.confidence >= 0.85) return Colors.green.shade600;
    if (result.confidence >= 0.75) return Colors.blue.shade600;
    if (result.confidence >= 0.60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _getConfidenceLabel() {
    if (result.confidence >= 0.85) return 'EXCELLENT';
    if (result.confidence >= 0.75) return 'GOOD';
    if (result.confidence >= 0.60) return 'FAIR';
    return 'LOW';
  }

  Color _getFreshnessColor() {
    switch (result.condition) {
      case 'Segar':
      case 'Sangat Segar':
        return Colors.green.shade600;
      case 'Cukup Segar':
        return Colors.orange.shade600;
      case 'Kurang Segar':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
