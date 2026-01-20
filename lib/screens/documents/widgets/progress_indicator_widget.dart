// lib/screens/document_upload/widgets/progress_indicator_widget.dart

import 'package:flutter/material.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Map<int, String>? documentStatuses; // step -> status mapping

  const ProgressIndicatorWidget({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.documentStatuses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = (currentStep / totalSteps);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$currentStep/$totalSteps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              int step = index + 1;
              bool isCurrent = step == currentStep;
              String? status = documentStatuses?[step];
              bool isCompleted = step < currentStep && status == null; // Sudah diupload tapi belum ada status dari API

              // Tentukan warna berdasarkan status
              Color stepColor;
              IconData? stepIcon;
              
              // Jika ada status dari API, gunakan warna sesuai status
              if (status == 'approved') {
                stepColor = Colors.green; // Hijau - Disetujui
                stepIcon = Icons.check;
              } else if (status == 'pending') {
                stepColor = Colors.orange; // Orange - Menunggu verifikasi
                stepIcon = Icons.schedule;
              } else if (status == 'rejected') {
                stepColor = Colors.red; // Merah - Ditolak
                stepIcon = Icons.close;
              } else if (isCompleted) {
                // Step yang sudah diupload (user baru)
                stepColor = Colors.green; // Hijau - Sudah dikirim
                stepIcon = Icons.send;
              } else {
                // Jika tidak ada status (belum pernah upload)
                if (isCurrent) {
                  stepColor = Colors.blue; // Biru - Sedang diisi
                  stepIcon = null;
                } else {
                  stepColor = Colors.grey[300]!; // Abu - Belum diisi
                  stepIcon = null;
                }
              }

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stepColor,
                          border: Border.all(
                            color: isCurrent && status == null && !isCompleted ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: stepIcon != null
                              ? Icon(
                                  stepIcon,
                                  color: Colors.white,
                                  size: stepIcon == Icons.schedule ? 16 : 18,
                                )
                              : Text(
                                  '$step',
                                  style: TextStyle(
                                    color: isCurrent || status != null || isCompleted
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStepLabel(step),
                        style: TextStyle(
                          fontSize: 9,
                          color: isCurrent && status == null && !isCompleted
                              ? Colors.blue
                              : (status != null || isCompleted)
                                  ? stepColor
                                  : Colors.grey[600],
                          fontWeight: isCurrent && status == null && !isCompleted ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 1:
        return 'KTP';
      case 2:
        return 'Foto';
      case 3:
        return 'NPWP';
      case 4:
        return 'Buku';
      case 5:
        return 'Sertif';
      case 6:
        return 'BST';
      case 7:
        return 'Sehat';
      case 8:
        return 'SKCK';
      default:
        return '';
    }
  }
}