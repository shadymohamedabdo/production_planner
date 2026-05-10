import 'package:flutter/material.dart';
import '../models/order.dart';
import '../database/database_helper.dart';

class OrderForm extends StatefulWidget {
  final VoidCallback onSaved;
  final Order? order; // رجعنا السطر ده عشان التعديل يشتغل

  OrderForm({required this.onSaved, this.order}); // أضفنا this.order هنا

  @override
  _OrderFormState createState() => _OrderFormState();
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
      // حالة التعديل: بنملى البيانات من الأوردر اللي جاي
      _customerController.text = widget.order!.customerName;
      _orderRows.add({
        'width': TextEditingController(text: widget.order!.width.toString()),
        'grams': TextEditingController(text: widget.order!.grams.toString()),
        'tons': TextEditingController(text: widget.order!.totalTons.toString()),
        'qty': TextEditingController(text: widget.order!.quantity.toString()),
        'diameter': widget.order!.diameter,
      });
    } else {
      // حالة إضافة جديد
      _addNewRow();
    }
  }

  void _addNewRow() {
    setState(() {
      _orderRows.add({
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
    double kiloFactor = _diameterSpecs[row['diameter']] ?? 0;

    if (tons > 0 && width > 0) {
      double totalWeightKilo = tons * 1000;
      double avgRollWeight = width * kiloFactor;
      double res = totalWeightKilo /avgRollWeight ;

      setState(() {
        row['qty'].text = res.round().toString();
      });
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    for (var row in _orderRows) {
      row['width'].dispose();
      row['grams'].dispose();
      row['tons'].dispose();
      row['qty'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.order != null;

    return AlertDialog(
      title: Text(isEditing ? 'تعديل الطلب' : 'إضافة أوردرات متعددة'),
      content: SizedBox(
        width: 900,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'اسم العميل', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              ..._orderRows.asMap().entries.map((entry) {
                int idx = entry.key;
                var row = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButton<double>(
                          value: row['diameter'],
                          isExpanded: true,
                          items: _diameterSpecs.keys.map((d) => DropdownMenuItem(value: d, child: Text('$d سم'))).toList(),
                          onChanged: (val) {
                            setState(() => row['diameter'] = val);
                            _calculateRow(idx);
                          },
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(flex: 2, child: TextField(controller: row['width'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'العرض', border: OutlineInputBorder()), onChanged: (_) => _calculateRow(idx))),
                      const SizedBox(width: 5),
                      Expanded(flex: 2, child: TextField(controller: row['grams'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الجرام', border: OutlineInputBorder()))),
                      const SizedBox(width: 5),
                      Expanded(flex: 2, child: TextField(controller: row['tons'], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الطن', border: OutlineInputBorder()), onChanged: (_) => _calculateRow(idx))),
                      const SizedBox(width: 5),
                      Expanded(flex: 1, child: TextField(controller: row['qty'], readOnly: true, textAlign: TextAlign.center, decoration: InputDecoration(fillColor: Colors.grey[200], filled: true, border: const OutlineInputBorder()))),
                      // في حالة التعديل بنخفي زرار الحذف عشان بنعدل سطر واحد بس
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
                  label: const Text('إضافة مقاس جديد للعميل'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () async {
            if (_customerController.text.isEmpty) return;

            for (var row in _orderRows) {
              final order = Order(
                id: isEditing ? widget.order!.id : null, // لو تعديل بنبعت الـ ID
                customerName: _customerController.text,
                date: isEditing ? widget.order!.date : DateTime.now(),
                width: double.parse(row['width'].text),
                quantity: int.tryParse(row['qty'].text) ?? 0,
                grams: double.tryParse(row['grams'].text) ?? 0,
                totalTons: double.parse(row['tons'].text),
                diameter: row['diameter'],
                diameterWeight: _diameterSpecs[row['diameter']]!,
                isPlanned: isEditing ? widget.order!.isPlanned : false,
              );

              if (isEditing) {
                await DatabaseHelper().updateOrder(order);
              } else {
                await DatabaseHelper().insertOrder(order);
              }
            }
            widget.onSaved();
            Navigator.pop(context);
          },
          child: Text(isEditing ? 'تحديث البيانات' : 'حفظ الكل'),
        ),
      ],
    );
  }
}