import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_card/pocket_card.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_form_fields.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

class EditPocketScreen extends ConsumerStatefulWidget {
  final Pocket pocket;

  const EditPocketScreen({super.key, required this.pocket});

  @override
  ConsumerState<EditPocketScreen> createState() => _EditPocketScreenState();
}

class _EditPocketScreenState extends ConsumerState<EditPocketScreen> {
  late TextEditingController _nameController;
  late TextEditingController _purposeController;
  late TextEditingController _emoticonController;
  late ColorGradient _selectedGradient;
  late String _currency;
  List<ColorGradient> _gradients = [];
  bool _saving = false;
  late Pocket _previewPocket;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pocket.name);
    _purposeController = TextEditingController(text: widget.pocket.purpose);
    _emoticonController = TextEditingController(text: widget.pocket.emoticon);
    _selectedGradient = widget.pocket.colorGradient;
    _currency = widget.pocket.currency;
    _previewPocket = widget.pocket;

    _nameController.addListener(_updatePreview);
    _purposeController.addListener(_updatePreview);
    _emoticonController.addListener(_updatePreview);

    _loadGradients();
  }

  void _updatePreview() {
    setState(() {
      _previewPocket = widget.pocket.copyWith(
        name: _nameController.text,
        purpose: _purposeController.text,
        emoticon: _emoticonController.text,
        colorGradient: _selectedGradient,
        currency: _currency,
      );
    });
  }

  Future<void> _loadGradients() async {
    final gradients =
        await ref.read(colorGradientRepositoryProvider).getAllGradients();
    if (mounted) setState(() => _gradients = gradients);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _emoticonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.pocket.copyWith(
      name: _nameController.text,
      purpose: _purposeController.text,
      emoticon: _emoticonController.text,
      colorGradient: _selectedGradient,
      currency: _currency,
      updatedAt: DateTime.now(),
    );
    await ref.read(pocketViewModelProvider.notifier).updatePocket(updated);
    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            expandedHeight: 150.0,
            flexibleSpace: const FlexibleSpaceBar(title: Text('Edit Pocket')),
          ),
          SliverToBoxAdapter(child: PocketCard(pocket: _previewPocket)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PocketFormFields(
                    nameController: _nameController,
                    purposeController: _purposeController,
                    emoticonController: _emoticonController,
                    gradients: _gradients,
                    selectedGradient: _selectedGradient,
                    onGradientSelected: (gradient) {
                      setState(() {
                        _selectedGradient = gradient;
                        _updatePreview();
                      });
                    },
                    currency: _currency,
                    onCurrencyChanged: (c) {
                      setState(() {
                        _currency = c;
                        _updatePreview();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon:
                        _saving
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
