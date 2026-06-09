import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rocket_pocket/data/model/color_gradient.dart';
import 'package:rocket_pocket/data/model/pocket.dart';
import 'package:rocket_pocket/repositories/color_gradient_repository.dart';
import 'package:rocket_pocket/screens/0_widgets/gradient_picker/gradient_picker.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_form_fields.dart';
import 'package:rocket_pocket/screens/0_widgets/pocket_header.dart';
import 'package:rocket_pocket/viewmodels/pocket_view_model.dart';

class EditPocketScreen extends ConsumerStatefulWidget {
  final Pocket pocket;

  const EditPocketScreen({super.key, required this.pocket});

  @override
  ConsumerState<EditPocketScreen> createState() => _EditPocketScreenState();
}

class _EditPocketScreenState extends ConsumerState<EditPocketScreen> {
  static const double _expandedHeight = 250.0;
  late TextEditingController _nameController;
  late TextEditingController _iconController;
  late ColorGradient _selectedGradient;
  late String _currency;
  List<ColorGradient> _gradients = [];
  bool _saving = false;
  late Pocket _previewPocket;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pocket.name);
    _iconController = TextEditingController(text: widget.pocket.icon);
    _selectedGradient = widget.pocket.colorGradient;
    _currency = widget.pocket.currency;
    _previewPocket = widget.pocket;

    _nameController.addListener(() => setState(_updatePreview));
    _iconController.addListener(() => setState(_updatePreview));

    _loadGradients();
  }

  void _updatePreview() {
    _previewPocket = widget.pocket.copyWith(
      name: _nameController.text,
      icon: _iconController.text,
      colorGradient: _selectedGradient,
      currency: _currency,
    );
  }

  Future<void> _loadGradients() async {
    final gradients =
        await ref.read(colorGradientRepositoryProvider).getAllGradients();
    if (mounted) setState(() => _gradients = gradients);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.pocket.copyWith(
      name: _nameController.text,
      icon: _iconController.text,
      colorGradient: _selectedGradient,
      currency: _currency,
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(pocketViewModelProvider.notifier).updatePocket(updated);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save pocket. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _expandedHeight,
            backgroundColor: _previewPocket.colorGradient.colors.first,
            foregroundColor: Colors.white,
            title: const Text('Edit Pocket'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: PocketHeader(pocket: _previewPocket),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_gradients.isNotEmpty)
                    GradientPicker(
                      gradients: _gradients,
                      selectedColor: _selectedGradient,
                      onSelected: (gradient) {
                        setState(() {
                          _selectedGradient = gradient;
                          _updatePreview();
                        });
                      },
                    ),
                  if (_gradients.isNotEmpty) const SizedBox(height: 16),
                  PocketFormFields(
                    nameController: _nameController,
                    iconController: _iconController,
                    showGradientPicker: false,
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
