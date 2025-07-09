import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart' as pb;
import 'package:nexo/presentation/theme/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexo/data/auth_repository.dart';

class ProfessionalCard extends ConsumerWidget {
  final pb.RecordModel professionalProfile;
  final ValueChanged<pb.RecordModel> onViewDetails;

  const ProfessionalCard({
    super.key,
    required this.professionalProfile,
    required this.onViewDetails,
  });

  String? _getAvatarUrl(pb.RecordModel professionalProfile, WidgetRef ref) {
    final userRecord = professionalProfile.get<pb.RecordModel?>('expand.user');
    if (userRecord != null) {
      final avatar = userRecord.get<String?>('avatar');
      if (avatar != null && avatar.isNotEmpty) {
        final pocketBase = ref.read(authRepositoryProvider).pocketBase;

        return pocketBase.files.getURL(userRecord, avatar).toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryTextColor = isDarkMode
        ? DarkAppColors.primaryText
        : LightAppColors.primaryText;
    final secondaryTextColor = isDarkMode
        ? DarkAppColors.secondaryText
        : LightAppColors.secondaryText;
    final cardColor = isDarkMode
        ? DarkAppColors.cardAndInputFields
        : LightAppColors.cardAndInputFields;

    final String professionalName =
        professionalProfile.get<String?>('expand.user.name') ??
        'Nombre Desconocido';
    final String category =
        professionalProfile.get<String?>('category') ?? 'Sin Categoría';
    final double hourlyRate =
        professionalProfile.get<double?>('hourly_rate') ?? 0.0;
    final String businessName =
        professionalProfile.get<String?>('business_name') ?? 'Sin Negocio';

    final avatarUrl = _getAvatarUrl(professionalProfile, ref);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onViewDetails(professionalProfile),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.1),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 40, color: secondaryTextColor)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      professionalName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${hourlyRate.toStringAsFixed(2)}/hr',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: secondaryTextColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
