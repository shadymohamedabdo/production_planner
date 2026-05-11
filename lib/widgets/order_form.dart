import 'package:flutter/material.dart';
import '../models/order.dart';
import '../database/database_helper.dart';

class OrderForm extends StatefulWidget {
  final VoidCallback onSaved;
  final Order? order;

  const OrderForm({super.key, required this.onSaved, this.order});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _customerController = TextEditingController();
  final List<Map<String, dynamic>> _orderRows = [];

  final Map<double, double> _diameterSpecs = {
    120.0: 8.0,
    125.0: 8.5,
    140.0: 11.5,
  };

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      // حالة التعديل
      _customerController.text = widget.order!.customerName;
      _orderRows.add({
        'salesOrder': TextEditingController(text: widget.order!.salesOrder ?? ''),
        'width': TextEditingController(text: widget.order!.width.toString()),
        'grams': TextEditingController(text: widget.order!.grams.toString()),
        'tons': TextEditingController(text: widget.order!.totalTons.toString()),
        'qty': TextEditingController(text: widget.order!.quantity.toString()),
        'diameter': widget.order!.diameter,
      });
    } else {
      _addNewRow();
    }
  }

  void _addNewRow() {
    setState(() {
      _orderRows.add({
        'salesOrder': TextEditingController(), // أضفنا الكنترولر هنا في كل سطر
        'width': TextEditingController(),
        'grams': TextEditingController(),
        'tons': TextEditingController(),
        'qty': TextEditingController(),
        'diameter': 120.0,
      });
    });
  }

  void _calculateRow(int index) {
    var row = _orderRows[index];
    double tons = double.tryParse(row['tons'].text) ?? 0;
    double width = double.tryParse(row['width'].text) ?? 0;
    double diamWeight = _diameterSpecs[row['diameter']] ?? 0;

    if (tons > 0 && width > 0 && diamWeight > 0) {
      double rollWeight = width * diamWeight;
      int calculatedQty = (tons * 1000 / rollWeight).round();
      row['qty'].text = calculatedQty.toString();
    }
  }

  @override
  @override
  void dispose() {
    // التأكد من إغلاق الكنترولر الرئيسي
    _customerController.dispose();

    // التأكد من إغلاق كنترولرات الصفوف بشكل آمن
    for (var row in _orderRows) {
      // علامة الـ ?. بتضمن إن لو الكنترولر null مش هيضرب error
      row['salesOrder']?.dispose();
      row['width']?.dispose();
      row['grams']?.dispose();
      row['tons']?.dispose();
      row['qty']?.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.order != null;
    return AlertDialog(
      title: Text(isEditing ? 'تعديل الطلب' : 'إضافة أوردرات متعددة'),
      content: SizedBox(
        width: 1100, // زيادة العرض قليلاً لتناسب الخانة الجديدة
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customerController,
                decoration: const InputDecoration(
                    labelText: 'اسم العميل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person)
                ),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 2),

              // عناوين الخانات لتسهيل القراءة
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                child: Row(
                  children: const [
                    Expanded(flex: 2, child: Text("رقم أمر البيع (S.O)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 5),
                    Expanded(flex: 2, child: Text("القطر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 5),
                    Expanded(flex: 2, child: Text("العرض (سم)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 5),
                    Expanded(flex: 2, child: Text("الجرام", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 5),
                    Expanded(flex: 2, child: Text("الوزن (طن)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 5),
                    Expanded(flex: 1, child: Text("بكر", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    SizedBox(width: 40),
                  ],
                ),
              ),

              ..._orderRows.asMap().entries.map((entry) {
                int idx = entry.key;
                var row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      // خانة Sales Order لكل سطر
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: row['salesOrder'],
                          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'S.O #'),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<double>(
                          value: row['diameter'],
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 5)),
                          items: _diameterSpecs.keys.map((d) => DropdownMenuItem(value: d, child: Text('$d سم'))).toList(),
                          onChanged: (val) {
                            setState(() => row['diameter'] = val);
                            _calculateRow(idx);
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(flex: 2, child: TextField(controller: row['width'], keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder()), onChanged: (_) => _calculateRow(idx))),
                      const SizedBox(width: 5),
                      Expanded(flex: 2, child: TextField(controller: row['grams'], keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder()))),
                      const SizedBox(width: 5),
                      Expanded(flex: 2, child: TextField(controller: row['tons'], keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder()), onChanged: (_) => _calculateRow(idx))),
                      const SizedBox(width: 5),
                      Expanded(flex: 1, child: TextField(controller: row['qty'], readOnly: true, textAlign: TextAlign.center, decoration: InputDecoration(fillColor: Colors.grey[200], filled: true, border: const OutlineInputBorder()))),
                      if (!isEditing)
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _orderRows.removeAt(idx))),
                    ],
                  ),
                );
              }).toList(),
              if (!isEditing)
                ElevatedButton.icon(
                  onPressed: _addNewRow,
                  icon: const Icon(Icons.add_box),
                  label: const Text('إضافة مقاس/أمر بيع جديد'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (_customerController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء إدخال اسم العميل')));
              return;
            }

            try {
              for (var row in _orderRows) {
                final order = Order(
                  id: isEditing ? widget.order!.id : null,
                  date: isEditing ? widget.order!.date : DateTime.now(),
                  customerName: _customerController.text.trim(),
                  // سحب رقم أمر البيع من السطر نفسه
                  salesOrder: row['salesOrder'].text.trim(),
                  width: double.parse(row['width'].text),
                  quantity: int.parse(row['qty'].text),
                  grams: double.tryParse(row['grams'].text) ?? 0,
                  totalTons: double.parse(row['tons'].text),
                  diameter: row['diameter'],
                  diameterWeight: _diameterSpecs[row['diameter']]!,
                  status: isEditing ? widget.order!.status : "انتظار",
                );

                if (isEditing) {
                  await DatabaseHelper().updateOrder(order);
                } else {
                  await DatabaseHelper().insertOrder(order);
                }
              }
              widget.onSaved();
              Navigator.pop(context);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
            }
          },
          child: Text(isEditing ? 'تحديث البيانات' : 'حفظ الكل'),
        ),
      ],
    );
  }
}