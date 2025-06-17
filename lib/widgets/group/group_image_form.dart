import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:fp_kelompok_1_ppb_c/services/image_service.dart';
import 'package:fp_kelompok_1_ppb_c/services/group_service.dart';

class GroupImageForm extends StatefulWidget {
  final Uint8List image;
  final String groupId;
  final String userId;

  const GroupImageForm({
    super.key,
    required this.image,
    required this.groupId,
    required this.userId,
  });

  @override
  State<GroupImageForm> createState() => _GroupImageFormState();
}

class _GroupImageFormState extends State<GroupImageForm> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<ui.Image> _convertToUiImage(img.Image image) async {
    final Uint8List bytes = Uint8List.fromList(
      image.getBytes(order: img.ChannelOrder.rgba),
    );

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      bytes,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    return completer.future;
  }

  void _showPickImageDialog() {
    File? _tempImage; // Simpan sementara
    bool localLoading = false;
    Image? _image = Image.memory(widget.image);

    if (widget.image.isEmpty) {
      _image = null; // Jika tidak ada gambar, set ke null
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> _pickImage(ImageSource source) async {
              setDialogState(() => localLoading = true);
              try {
                final XFile? image = await _picker.pickImage(source: source);
                if (image != null) {
                  final File file = File(image.path);

                  // Validasi gambar
                  final String? validationError = await ImageValidator.validate(
                    file,
                  );
                  if (validationError != null) {
                    _showOverlayMessage(validationError, isError: true);
                    return;
                  }

                  setDialogState(() {
                    _tempImage = file;
                  });
                  _showOverlayMessage('Gambar berhasil dipilih');
                } else {
                  _showOverlayMessage(
                    'Tidak ada gambar yang dipilih',
                    isError: true,
                  );
                }
              } catch (e) {
                print('Error picking image: $e');
                _showOverlayMessage('Gagal memilih gambar: $e', isError: true);
              } finally {
                setDialogState(() => localLoading = false);
              }
            }

            void _removeImage() {
              setDialogState(() => _image = null);
              _showOverlayMessage('Foto profil dihapus');
            }

            return AlertDialog(
              title: const Text('Ubah Foto Profil'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          // offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child:
                        _tempImage != null
                            ? CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.red[50],
                              backgroundImage: FileImage(_tempImage!),
                            )
                            : _image != null
                            ? CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue[50],
                              backgroundImage: _image!.image,
                            )
                            : const CircleAvatar(
                              radius: 60,
                              backgroundColor: Color(0xFFFFE4BD),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFFF4A44A),
                                size: 40,
                              ),
                            ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            localLoading
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo, color: Colors.black),
                        label: const Text(
                          'Galeri',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            localLoading
                                ? null
                                : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, color: Colors.black),
                        label: const Text(
                          'Kamera',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_image != null)
                    ElevatedButton.icon(
                      onPressed: localLoading ? null : _removeImage,
                      icon: Icon(Icons.delete, color: Color(0xFFFFF4E5)),
                      label: Text(
                        'Hapus Foto Profil',
                        style: TextStyle(color: Color(0xFFFFF4E5)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF4A44A),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    overlayColor: Color(0xFFF4A44A),
                  ),
                  onPressed:
                      localLoading
                          ? null
                          : () async {
                            Uint8List? savedImageBytes;

                            setState(() {
                              _selectedImage = _tempImage;
                            });

                            if (_selectedImage != null) {
                              final bytes = await _selectedImage!.readAsBytes();
                              final decodedImg = img.decodeImage(bytes);
                              if (decodedImg != null) {
                                final uiImage = await _convertToUiImage(
                                  decodedImg,
                                );
                                await GroupService.instance.updateGroupImage(
                                  groupId: widget.groupId,
                                  userId: widget.userId,
                                  image: uiImage,
                                );
                                savedImageBytes =
                                    bytes; // Store the bytes that were saved
                              }
                            } else if (_image == null) {
                              await GroupService.instance.updateGroupImage(
                                groupId: widget.groupId,
                                userId: widget.userId,
                                image: null,
                              );
                              savedImageBytes = null; // Image was removed
                            }

                            Navigator.of(context).pop();
                            _showOverlayMessage('Perubahan disimpan');
                          },
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Color(0xFFF4A44A)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOverlayMessage(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isError ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    Timer(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 16, bottom: 4),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(0xFFF4A44A),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: IconButton(
            icon: Icon(Icons.edit, size: 20, color: Colors.black),
            onPressed: _showPickImageDialog,
            tooltip: 'Edit Gambar',
          ),
        ),
      ],
    );
  }
}
