import 'package:flutter/material.dart';
import '../models/order.dart';
import '../database/database_helper.dart';

class OrderForm extends StatefulWidget {
  final VoidCallback onSaved;
  final Order? order; // أضفنا هذا السطر لاستقبال بيانات الطلب في حالة التعديل

  OrderForm({required this.onSaved, this.order}); // جعلناه اختيارياً

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _widthController = TextEditingController();
  final _quantityController = TextEditingController();
  final _gramsController = TextEditingController();
  final _tonsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // لو فيه طلب مبعوت، املأ البيانات في الحقول فوراً
    if (widget.order != null) {
      _customerController.text = widget.order!.customerName;
      _widthController.text = widget.order!.width.toString();
      _quantityController.text = widget.order!.quantity.toString();
      _gramsController.text = widget.order!.grams.toString();
      _tonsController.text = widget.order!.totalTons.toString();
      _selectedDate = widget.order!.date;
    }
  }

  @override
  void dispose() {
    // تنظيف الـ controllers عند إغلاق الشاشة
    _customerController.dispose();
    _widthController.dispose();
    _quantityController.dispose();
    _gramsController.dispose();
    _tonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تغيير العنوان بناءً على الحالة
    final isEditing = widget.order != null;

    return AlertDialog(
      title: Text(isEditing ? 'تعديل الطلب' : 'إضافة طلب جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'اسم العميل'),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _widthController,
                decoration: const InputDecoration(labelText: 'عرض البكرة (متر)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'عدد البكر'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _gramsController,
                decoration: const InputDecoration(labelText: 'الجرام'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: _tonsController,
                decoration: const InputDecoration(labelText: 'الكمية بالطن'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              ListTile(
                title: Text('التاريخ: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final order = Order(
                id: widget.order?.id, // مهم جداً: الاحتفاظ بنفس الـ ID لو بنعدل
                date: _selectedDate,
                customerName: _customerController.text,
                width: double.parse(_widthController.text),
                quantity: int.parse(_quantityController.text),
                grams: double.parse(_gramsController.text),
                totalTons: double.parse(_tonsController.text),
                isPlanned: widget.order?.isPlanned ?? false, // الحفاظ على حالة التخطيط
              );

              if (isEditing) {
                // تحديث البيانات في قاعدة البيانات
                final db = await DatabaseHelper().database;
                await db.update(
                  'orders',
                  order.toMap(),
                  where: 'id = ?',
                  whereArgs: [order.id],
                );
              } else {
                // إضافة جديد
                await DatabaseHelper().insertOrder(order);
              }

              widget.onSaved();
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'تعديل' : 'حفظ'),
        ),
      ],
    );
  }
}