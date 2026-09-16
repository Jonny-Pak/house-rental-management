import 'package:flutter/material.dart';
import '../../data/repositories/favorite_repository.dart';

/// A reusable heart button with optimistic UI update.
/// On tap, it immediately flips state, calls the API, and reverts on error.
class FavoriteButton extends StatefulWidget {
  final int propertyId;
  final bool initialIsFavorite;
  final FavoriteRepository repository;
  // Optional callback to notify parent of state change
  final ValueChanged<bool>? onToggled;

  const FavoriteButton({
    super.key,
    required this.propertyId,
    required this.repository,
    this.initialIsFavorite = false,
    this.onToggled,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool _isFavorite;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
  }

  Future<void> _toggle() async {
    if (_isLoading) return;

    // Optimistic update
    final previousState = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
      _isLoading = true;
    });

    try {
      final result = await widget.repository.toggleFavorite(widget.propertyId);
      if (mounted) {
        setState(() {
          _isFavorite = result;
          _isLoading = false;
        });
        widget.onToggled?.call(result);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
              ),
        onPressed: _toggle,
        tooltip: _isFavorite ? 'Bỏ lưu' : 'Lưu tin',
      ),
    );
  }
}
