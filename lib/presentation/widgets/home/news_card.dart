import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sosigi/app/theme/app_colors.dart';
import 'package:sosigi/app/theme/app_text_styles.dart';
import 'package:sosigi/domain/models/article.dart';
import 'package:sosigi/presentation/widgets/common/premium_card.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsCard extends StatelessWidget {
  final Article article;
  final Future<void> Function()? onBeforeOpen;
  final VoidCallback? onOpened;
  final VoidCallback? onToggleBookmark;
  final bool isRead;
  final bool isBookmarked;

  const NewsCard({
    super.key,
    required this.article,
    this.onBeforeOpen,
    this.onOpened,
    this.onToggleBookmark,
    this.isRead = false,
    this.isBookmarked = false,
  });

  Future<void> _openLink(BuildContext context) async {
    if (onBeforeOpen != null) {
      await onBeforeOpen!.call();
    }

    final uri = Uri.tryParse(article.link);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('유효하지 않은 기사 링크입니다.'),
          ),
        );
      }
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (opened) {
      onOpened?.call();
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기사 링크를 열지 못했습니다. 잠시 후 다시 시도해 주세요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceText = article.publishedAt == null
        ? article.sourceName
        : '${article.sourceName} · ${DateFormat('MM.dd HH:mm').format(article.publishedAt!)}';

    final titleStyle = AppTextStyles.cardTitle.copyWith(
      fontSize: 13.5,
      height: 1.3,
      color: isRead ? AppColors.secondaryText : AppColors.primaryText,
    );

    return Opacity(
      opacity: isRead ? 0.72 : 1,
      child: PremiumCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _openLink(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sourceText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                          if (article.matchedKeywords.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                article.matchedKeywords.first,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onToggleBookmark,
              icon: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isBookmarked ? AppColors.navy : AppColors.secondaryText,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.secondaryText,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}