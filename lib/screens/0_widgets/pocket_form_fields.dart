import 'package:country_currency_pickers/country.dart';
import 'package:country_currency_pickers/currency_picker_dropdown.dart';
import 'package:country_currency_pickers/utils/utils.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/screens/0_widgets/gradient_picker/gradient_picker.dart';

/// Shared form fields for create and edit pocket screens.
/// Covers: name, purpose, emoticon, gradient picker, currency picker.
class PocketFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController purposeController;
  final TextEditingController emoticonController;
  final List<ColorGradient> gradients;
  final ColorGradient selectedGradient;
  final ValueChanged<ColorGradient> onGradientSelected;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;

  const PocketFormFields({
    super.key,
    required this.nameController,
    required this.purposeController,
    required this.emoticonController,
    required this.gradients,
    required this.selectedGradient,
    required this.onGradientSelected,
    required this.currency,
    required this.onCurrencyChanged,
  });

  void _openEmojiPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return EmojiPicker(
          onEmojiSelected: (_, emoji) {
            emoticonController.text = emoji.emoji;
            Navigator.of(ctx).pop();
          },
          config: Config(
            height: 300,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              backgroundColor: cs.surface,
              emojiSizeMax:
                  28 *
                  (foundation.defaultTargetPlatform == TargetPlatform.iOS
                      ? 1.2
                      : 1.0),
            ),
            skinToneConfig: SkinToneConfig(
              dialogBackgroundColor: cs.surfaceContainer,
            ),
            categoryViewConfig: CategoryViewConfig(
              recentTabBehavior: RecentTabBehavior.NONE,
              backgroundColor: cs.surface,
              iconColor: cs.onSurfaceVariant,
              iconColorSelected: cs.primary,
              indicatorColor: cs.primary,
            ),
            bottomActionBarConfig: BottomActionBarConfig(
              backgroundColor: cs.surface,
              buttonColor: cs.primaryContainer,
              buttonIconColor: cs.onPrimaryContainer,
            ),
            searchViewConfig: SearchViewConfig(
              backgroundColor: cs.surface,
              buttonIconColor: cs.primary,
              inputTextStyle: TextStyle(color: cs.onSurface),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize your pocket',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Pocket Name',
            border: OutlineInputBorder(),
            icon: Icon(Icons.add_card),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: purposeController,
          decoration: const InputDecoration(
            labelText: 'Purpose',
            border: OutlineInputBorder(),
            icon: Icon(Icons.account_balance_wallet),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emoticonController,
          readOnly: true,
          onTap: () => _openEmojiPicker(context),
          decoration: const InputDecoration(
            labelText: 'Emoticon',
            border: OutlineInputBorder(),
            icon: Icon(Icons.emoji_emotions),
            hintText: 'Tap to pick an emoji',
          ),
        ),
        const SizedBox(height: 8),
        if (gradients.isNotEmpty)
          GradientPicker(
            gradients: gradients,
            selectedColor: selectedGradient,
            onSelected: onGradientSelected,
          ),
        const SizedBox(height: 16),
        CurrencyPickerDropdown(
          initialValue: currency,
          itemBuilder: _buildCurrencyItem,
          onValuePicked: (Country? country) {
            if (country != null) {
              onCurrencyChanged(country.currencyCode ?? currency);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCurrencyItem(Country country) => Row(
    children: [
      CountryPickerUtils.getDefaultFlagImage(country),
      const SizedBox(width: 16),
      Text('${country.currencyCode}'),
    ],
  );
}
