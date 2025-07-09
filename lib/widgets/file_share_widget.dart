import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/mqtt_service.dart';

class FileShareWidget extends StatefulWidget {
  final MqttService mqttService;
  
  const FileShareWidget({
    super.key,
    required this.mqttService,
  });

  @override
  State<FileShareWidget> createState() => _FileShareWidgetState();
}

class _FileShareWidgetState extends State<FileShareWidget> {
  bool _isSharing = false;
  
  Future<void> _pickAndShareFile() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isSharing = true;
      });
      
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (!mounted) return;
      
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          final file = File(filePath);
          
          // Show confirmation dialog for large files
          final fileSize = await file.length();
          
          if (!mounted) return;
          
          if (fileSize > 10 * 1024 * 1024) { // 10MB
            final shouldContinue = await _showLargeFileConfirmation(
              context,
              filename: result.files.first.name,
              fileSize: fileSize,
            );
            
            if (shouldContinue != true) {
              setState(() {
                _isSharing = false;
              });
              return;
            }
          }
          
          // Share the file
          final success = await widget.mqttService.shareFile(file);
          
          if (!mounted) return;
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sharing file: ${result.files.first.name}')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to share file')),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }
  
  Future<bool?> _showLargeFileConfirmation(
    BuildContext context, {
    required String filename,
    required int fileSize,
  }) async {
    final formattedSize = _formatFileSize(fileSize);
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Large File?'),
        content: Text(
          'The file "$filename" is $formattedSize in size. '
          'Sharing large files may take some time. '
          'Do you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SHARE'),
          ),
        ],
      ),
    );
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share Files',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Share files with all connected participants',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isSharing ? null : _pickAndShareFile,
          icon: _isSharing 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.file_upload),
          label: Text(_isSharing ? 'Sharing...' : 'Select & Share File'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
