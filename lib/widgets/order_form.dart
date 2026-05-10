import 'package:flutter/material.dart';
import '../models/order.dart';
import '../database/database_helper.dart';

class OrderForm extends StatefulWidget {
  final VoidCallback onSaved;
  final Order? order;

  OrderForm({required this.onSaved, this.order});

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();

  // المدخلات الأساسية
  final _customerController = TextEditingController();
  final _widthController = TextEditingController();
  final _quantityController = TextEditingController(); // محسوب تلقائياً
  final _gramsController = TextEditingController();
  final _tonsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  double? _selectedDiameter;
  final Map<double, double> _diameterSpecs = {
    120.0: 8.0,
    125.0: 8.5,
    140.0: 11.5,
  };

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _customerController.text = widget.order!.customerName;
      _widthController.text = widget.order!.width.toString();
      _quantityController.text = widget.order!.quantity.toString();
      _gramsController.text = widget.order!.grams.toString();
      _tonsController.text = widget.order!.totalTons.toString();
      _selectedDate = widget.order!.date;
      _selectedDiameter = widget.order!.diameter;
    } else {
      _selectedDiameter = 120.0; // القيمة الافتراضية
    }
  }

  // دالة الحساب التلقائي لعدد البكر
  void _calculateAutoFields() {
    if (_tonsController.text.isNotEmpty && _selectedDiameter != null) {
      try {
        double inputTons = double.parse(_tonsController.text);
        double kiloFactor = _diameterSpecs[_selectedDiameter!]!;
        double avgWeight = _selectedDiameter! * kiloFactor; // متوسط وزن البكرة

        if (inputTons != 0) {
          // عدد البكر = متوسط الوزن / رقم الطن (حسب طلبك)
          double rawQty = avgWeight / inputTons;
          setState(() {
            _quantityController.text = rawQty.round().toString();
          });
        }
      } catch (e) {}
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _widthController.dispose();
    _quantityController.dispose();
    _gramsController.dispose();
    _tonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.order != null;

    return AlertDialog(
      title: Text(isEditing ? 'تعديل الطلب' : 'إضافة طلب جديد'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400, // تحديد عرض مناسب للفورم
          child: SingleChildScrollView( // عشان لو الشاشة صغيرة المستخدم يقدر يسكرول
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. اسم العميل
                TextFormField(
                  controller: _customerController,
                  decoration: const InputDecoration(labelText: 'اسم العميل', prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 10),

                // 2. اختيار القطر
                DropdownButtonFormField<double>(
                  value: _selectedDiameter,
                  decoration: const InputDecoration(labelText: 'القطر (سم)', prefixIcon: Icon(Icons.straighten)),
                  items: _diameterSpecs.keys.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text("$d سم (يعادل ${_diameterSpecs[d]} ك)")
                  )).toList(),
                  onChanged: (val) {
                    setState(() => _selectedDiameter = val);
                    _calculateAutoFields();
                  },
                ),
                const SizedBox(height: 10),

                // 3. العرض والجرام في سطر واحد
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        decoration: const InputDecoration(labelText: 'العرض (م)'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _gramsController,
                        decoration: const InputDecoration(labelText: 'الجرام'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. الطن وعدد البكر (المحسوب)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tonsController,
                        decoration: const InputDecoration(labelText: 'الطن'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _calculateAutoFields(),
                        validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'عدد البكر',
                          filled: true,
                          fillColor: Colors.blueGrey,
                        ),
                        readOnly: true, // للقراءة فقط لأنه محسوب
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. التاريخ
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final order = Order(
                id: widget.order?.id,
                date: _selectedDate,
                customerName: _customerController.text,
                width: double.parse(_widthController.text),
                quantity: int.parse(_quantityController.text),
                grams: double.parse(_gramsController.text),
                totalTons: double.parse(_tonsController.text),
                diameter: _selectedDiameter!,
                diameterWeight: _diameterSpecs[_selectedDiameter!]!,
                isPlanned: widget.order?.isPlanned ?? false,
              );

              if (isEditing) {
                await DatabaseHelper().updateOrder(order);
              } else {
                await DatabaseHelper().insertOrder(order);
              }
              widget.onSaved();
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'تحديث' : 'حفظ الطلب'),
        ),
      ],
    );
  }
}