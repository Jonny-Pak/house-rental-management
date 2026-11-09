import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../listing/data/models/listing_model.dart';

class ChatListingCard extends StatelessWidget {
  const ChatListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.distanceLabel,
  });
  final Listing listing;
  final VoidCallback onTap;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFE3EBE6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(13),
              ),
              child: AspectRatio(
                aspectRatio: 1.65,
                child: listing.imageUrl == null
                    ? _placeholder()
                    : Image.network(
                        listing.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => _placeholder(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 9, 9, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.address ?? 'Chưa có địa chỉ',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${NumberFormat.decimalPattern('vi_VN').format(listing.rentPrice)} đ/${listingRentUnit(listing.listingType)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${listing.areaSqm.toStringAsFixed(0)} m² · ${listingTypeLabel(listing.listingType)}',
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                  if (distanceLabel != null && distanceLabel!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        distanceLabel!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _placeholder() => const ColoredBox(
    color: Color(0xFFE6F1EA),
    child: Icon(
      Icons.home_work_outlined,
      color: AppColors.placeholder,
      size: 32,
    ),
  );
}
