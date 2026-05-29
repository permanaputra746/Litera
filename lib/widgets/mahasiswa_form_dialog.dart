import 'package:flutter/material.dart';
import '../models/mahasiswa_model.dart';
import '../utils/app_state.dart';

class MahasiswaFormDialog extends StatefulWidget {
  final Mahasiswa? initialData;
  final Function(Mahasiswa) onSave;

  const MahasiswaFormDialog({
    super.key,
    this.initialData,
    required this.onSave,
  });

  @override
  State<MahasiswaFormDialog> createState() => _MahasiswaFormDialogState();
}

class _MahasiswaFormDialogState extends State<MahasiswaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nimController;
  late TextEditingController _namaController;
  late TextEditingController _kelasController;
  late TextEditingController _jurusanController;
  late TextEditingController _umurController;

  @override
  void initState() {
    super.initState();
    _nimController = TextEditingController(text: widget.initialData?.nim ?? '');
    _namaController = TextEditingController(text: widget.initialData?.nama ?? '');
    _kelasController = TextEditingController(text: widget.initialData?.kelas != '-' ? widget.initialData?.kelas : '');
    _jurusanController = TextEditingController(text: widget.initialData?.jurusan != '-' ? widget.initialData?.jurusan : '');
    _umurController = TextEditingController(text: widget.initialData?.umur != null && widget.initialData!.umur > 0 ? widget.initialData!.umur.toString() : '');
  }

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    _kelasController.dispose();
    _jurusanController.dispose();
    _umurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialData == null ? AppState.getString('form_add_student') : AppState.getString('form_edit_student'),
        style: const TextStyle(color: Color(0xFF2E7D32)),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nimController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_nim'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_nim') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_name') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _kelasController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_class'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_class') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _jurusanController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_major'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_major') : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _umurController,
                decoration: InputDecoration(
                  labelText: AppState.getString('form_label_age'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? AppState.getString('form_err_age') : null,
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
                Mahasiswa(
                  nim: _nimController.text.trim(),
                  nama: _namaController.text.trim(),
                  kelas: _kelasController.text.trim(),
                  jurusan: _jurusanController.text.trim(),
                  umur: int.tryParse(_umurController.text.trim()) ?? 0,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
          ),
          child: Text(AppState.getString('save')),
        ),
      ],
    );
  }
}