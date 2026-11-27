import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/open_trip_model.dart';

/// Dialog Pemberian Rating & Ulasan untuk Penyelenggara setelah Open Trip selesai
Future<bool> showOrganizerRatingDialog(
  BuildContext context, {
  required OpenTripItem trip,
}) async {
  int selectedRating = 5;
  final commentCtrl = TextEditingController();
  final List<String> availableTags = [
    'Tepat Waktu',
    'Pemandu Ramah',
    'Rute Aman',
    'Penjelasan Menarik',
    'Koordinasi Rapi',
  ];
  final Set<String> selectedTags = {'Tepat Waktu', 'Pemandu Ramah'};

  final submitted = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (dialogCtx, setDialogState) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Beri Rating Penyelenggara',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.organizer.name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                ),
              ),
              Text(
                trip.title,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (idx) {
                    final star = idx + 1;
                    return IconButton(
                      onPressed: () =>
                          setDialogState(() => selectedRating = star),
                      icon: Icon(
                        star <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 34,
                        color: AppColors.warning,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: availableTags.map((tag) {
                  final active = selectedTags.contains(tag);
                  return FilterChip(
                    selected: active,
                    label: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.forest,
                      ),
                    ),
                    selectedColor: AppColors.forest,
                    backgroundColor: AppColors.bgCard,
                    checkmarkColor: Colors.white,
                    onSelected: (val) {
                      setDialogState(() {
                        if (val) {
                          selectedTags.add(tag);
                        } else {
                          selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Bagikan pengalaman Anda bersama penyelenggara ini...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
                  filled: true,
                  fillColor: AppColors.bgCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.sageBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final review = OrganizerReview(
                id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
                organizerId: trip.organizer.id,
                organizerName: trip.organizer.name,
                tripTitle: trip.title,
                reviewerName: 'Wisatawan WISGO',
                rating: selectedRating,
                comment: commentCtrl.text.trim().isEmpty
                    ? 'Perjalanan sangat teratur dan penyelenggara amanah!'
                    : commentCtrl.text.trim(),
                tags: selectedTags.toList(),
                createdAt: DateTime.now(),
              );
              OrganizerRatingStore.instance.addReview(review);
              trip.hasReviewedOrganizer = true;
              Navigator.pop(dialogCtx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: AppColors.cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Kirim Rating',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );

  return submitted == true;
}
