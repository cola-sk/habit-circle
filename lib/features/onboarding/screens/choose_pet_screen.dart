import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pet_species.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/pet_repository.dart';

class ChoosePetScreen extends ConsumerStatefulWidget {
  const ChoosePetScreen({super.key});

  @override
  ConsumerState<ChoosePetScreen> createState() => _ChoosePetScreenState();
}

class _ChoosePetScreenState extends ConsumerState<ChoosePetScreen> {
  PetSpecies? _selectedSpecies;
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择宠物')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选一只宠物吧！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Gap(6),
            const Text(
              '每天学习可以给它喂食，让它快乐成长 🌟',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),

            const Gap(28),

            // 宠物选择网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: PetSpecies.values.length,
              itemBuilder: (context, index) {
                final species = PetSpecies.values[index];
                final isSelected = _selectedSpecies == species;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSpecies = species),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(species.emoji,
                            style: const TextStyle(fontSize: 36)),
                        const Gap(6),
                        Text(
                          species.displayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(target: isSelected ? 1 : 0).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 150.ms,
                    );
              },
            ),

            if (_selectedSpecies != null) ...[
              const Gap(24),
              TextField(
                controller: _nameController,
                maxLength: 8,
                decoration: InputDecoration(
                  hintText: '给 ${_selectedSpecies!.displayName} 起个名字',
                  counterText: '',
                ),
              ),
            ],

            const Spacer(),

            ElevatedButton(
              onPressed: _selectedSpecies == null || _isLoading
                  ? null
                  : _confirm,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_selectedSpecies == null ? '请先选择宠物' : '确认，开始养！'),
            ),

            const Gap(16),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final species = _selectedSpecies!;
    final name = _nameController.text.trim().isEmpty
        ? species.displayName
        : _nameController.text.trim();

    setState(() => _isLoading = true);
    try {
      final uid = ref.read(currentUidProvider);
      if (uid == null) return;
      await ref.read(petRepositoryProvider).createPet(
            name: name,
            species: species,
          );
      if (mounted) context.go('/onboarding/circle');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
