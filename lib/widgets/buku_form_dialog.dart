import 'package:flutter/material.dart';
import '../models/buku_model.dart';
import '../utils/app_state.dart';

class BukuFormDialog extends StatefulWidget {
  final Buku? initialData;
  final Function(Buku) onSave;

  const BukuFormDialog({
    super.key,
    this.initialData,
    required this.onSave,
  });

  @override
  State<BukuFormDialog> createState() => _BukuFormDialogState();
}

class _BukuFormDialogState extends State<BukuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _judulController;
  late TextEditingController _penulisController;
  late TextEditingController _kategoriController;
  late TextEditingController _tahunTerbitController;
  late TextEditingController _lokasiRakController;
  late TextEditingController _stokController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialData?.id ?? '');
    _judulController = TextEditingController(text: widget.initialData?.judul ?? '');
    _penulisController = TextEditingController(text: widget.initialData?.penulis ?? '');
    _kategoriController = TextEditingController(text: widget.initialData?.kategori ?? '');
    _tahunTerbitController = TextEditingController(text: widget.initialData?.tahunTerbit ?? '');
    _lokasiRakController = TextEditingController(text: widget.initialData?.lokasiRak ?? '');
    _stokController = TextEditingController(text: widget.initialData?.stok.toString() ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _judulController.dispose();
    _penulisController.dispose();
    _kategoriController.dispose();
    _tahunTerbitController.dispose();
    _lokasiRakController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    return AlertDialog(
      title: Text(
        isEdit ? AppState.getString('form_edit_book') : AppState.getString('form_add_book'),
        style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _idController,
                enabled: !isEdit,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_book_id'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_id') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_title'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.book),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_title') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _penulisController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_writer'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_writer') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kategoriController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_category'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.category),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_category') : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tahunTerbitController,
                      decoration: InputDecoration(
                        labelText: AppState.getString('form_label_pub_year'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_required') : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lokasiRakController,
                      decoration: InputDecoration(
                        labelText: AppState.getString('form_label_shelf'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_required') : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stokController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_stock'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_stock') : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppState.getString('cancel'), style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                Buku(
                  id: _idController.text.trim(),
                  judul: _judulController.text.trim(),
                  penulis: _penulisController.text.trim(),
                  kategori: _kategoriController.text.trim(),
                  tahunTerbit: _tahunTerbitController.text.trim(),
                  lokasiRak: _lokasiRakController.text.trim(),
                  cover: '', // empty defaults to placeholder icon
                  stok: int.tryParse(_stokController.text) ?? 0,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
          ),
          child: Text(AppState.getString('save')),
        ),
      ],
    );
  }
}