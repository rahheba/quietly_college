import 'package:flutter/material.dart';
import 'package:quietly/utils/service/dns_service.dart';
import 'package:quietly/utils/methods/custom_snackbar.dart';

class ClassModeButton extends StatefulWidget {
  const ClassModeButton({Key? key}) : super(key: key);

  @override
  _ClassModeButtonState createState() => _ClassModeButtonState();
}

class _ClassModeButtonState extends State<ClassModeButton> {
  final DndService _dndService = DndService();
  bool _isClassMode = false;
  bool _isLoading = false;

  Future<void> _toggleClassMode() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      if (!_isClassMode) {
        // Enable Class Mode (Mute)
        if (!await _dndService.hasAccess()) {
          await _dndService.openSettings();
          return;
        }
        await _dndService.setSilent();
        setState(() => _isClassMode = true);
        if (mounted) {
          showCustomSnackBar(
            context: context,
            message: 'Class Mode: Muted',
            status: SnackStatus.success,
          );
        }
      } else {
        // Disable Class Mode (Unmute)
        await _dndService.restore();
        setState(() => _isClassMode = false);
        if (mounted) {
          showCustomSnackBar(
            context: context,
            message: 'Class Mode: Unmuted',
            status: SnackStatus.info,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Error: ${e.toString()}',
          status: SnackStatus.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _toggleClassMode,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Icon(_isClassMode ? Icons.school : Icons.school_outlined),
      label: Text(_isClassMode ? 'Class Mode: ON' : 'Class Mode: OFF'),
      backgroundColor: _isClassMode ? Colors.red : Theme.of(context).primaryColor,
      heroTag: 'class_mode_button',
    );
  }
}

