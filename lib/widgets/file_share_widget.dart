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
  String _selectedTargetType = 'all'; // 'all' or 'specific'
  String? _selectedClientIp;
  
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
          String? targetIp;
          if (_selectedTargetType == 'specific' && _selectedClientIp != null) {
            targetIp = _selectedClientIp;
            debugPrint('🎯 Sharing file with specific client: $targetIp');
          } else {
            debugPrint('📢 Sharing file with all clients');
          }
          
          final success = await widget.mqttService.shareFile(file, targetIp: targetIp);
          
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
    final connectedClients = widget.mqttService.connectedClients;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: Colors.black, size: 22),
              const SizedBox(width: 8),
              Text(
                'Share Files',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Send files to participants',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const Divider(height: 24, thickness: 0.7, color: Colors.black12),
          Text(
            'Share with:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('All participants', style: TextStyle(color: Colors.black)),
            value: 'all',
            groupValue: _selectedTargetType,
            onChanged: (value) {
              setState(() {
                _selectedTargetType = value!;
                _selectedClientIp = null;
              });
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.black,
          ),
          RadioListTile<String>(
            title: const Text('Specific participant', style: TextStyle(color: Colors.black)),
            value: 'specific',
            groupValue: _selectedTargetType,
            onChanged: connectedClients.isEmpty ? null : (value) {
              setState(() {
                _selectedTargetType = value!;
                if (_selectedClientIp == null && connectedClients.isNotEmpty) {
                  _selectedClientIp = connectedClients.first.ipAddress;
                }
              });
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.black,
          ),
          if (_selectedTargetType == 'specific') ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: connectedClients.isEmpty
                  ? const Text(
                      'No connected clients available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : DropdownButton<String>(
                      value: _selectedClientIp,
                      hint: const Text('Select client', style: TextStyle(color: Colors.black54)),
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      items: connectedClients.map((client) {
                        return DropdownMenuItem<String>(
                          value: client.ipAddress,
                          child: Text(
                            '${client.deviceName} (${client.ipAddress})',
                            style: const TextStyle(fontSize: 13, color: Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClientIp = value;
                        });
                      },
                    ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSharing ||
                      (_selectedTargetType == 'specific' &&
                          (connectedClients.isEmpty || _selectedClientIp == null))
                  ? null
                  : _pickAndShareFile,
              icon: _isSharing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.file_upload, color: Colors.white),
              label: Text(
                _isSharing ? 'Sharing...' : 'Select & Share File',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
