import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/orders_cubit.dart';
import '../models/order.dart';

class OrderForm extends StatefulWidget {
  final Order? order;

  const OrderForm({super.key, this.order});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
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
      // حالة التعديل: تعبئة البيانات الموجودة
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
      // حالة إضافة جديد: نبدأ بسطر فاضي
      _addNewRow();
    }
  }

  void _addNewRow() {
    setState(() {
      _orderRows.add({
        'salesOrder': TextEditingController(),
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
    } else {
      row['qty'].text = '';
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    for (var row in _orderRows) {
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
        width: 1100,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _customerController,
                  decoration: const InputDecoration(
                    labelText: 'اسم العميل *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'اسم العميل مطلوب' : null,
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 2),
                _buildTableHeader(),
                ..._orderRows.asMap().entries.map((entry) =>
                    _buildOrderRow(entry.key, entry.value, isEditing)),
                // ✅ الآن يمكن إضافة صفوف جديدة حتى في وضع التعديل
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ElevatedButton.icon(
                    onPressed: _addNewRow,
                    icon: const Icon(Icons.add_box),
                    label: const Text('إضافة مقاس جديد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () => _handleSave(isEditing),
          child: Text(isEditing ? 'تحديث البيانات' : 'حفظ الكل'),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
          SizedBox(width: 30), // مسافة للترقيم
          Expanded(flex: 2, child: Text("رقم S.O", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("القطر", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("العرض", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("الجرام", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("طن", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 1, child: Text("بكر", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildOrderRow(int idx, Map<String, dynamic> row, bool isEditing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 5),
      decoration: BoxDecoration(
        color: idx % 2 == 0 ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${idx + 1}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['salesOrder'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '#',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (value) =>
              value == null || value.trim().isEmpty ? 'مطلوب' : null,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<double>(
              initialValue: row['diameter'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              items: _diameterSpecs.keys.map((d) {
                return DropdownMenuItem(value: d, child: Text('$d سم'));
              }).toList(),
              onChanged: (val) {
                setState(() => row['diameter'] = val);
                _calculateRow(idx);
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['width'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'سم',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'مطلوب';
                if (double.tryParse(value) == null) return 'رقم غير صحيح';
                return null;
              },
              onChanged: (_) => _calculateRow(idx),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['grams'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'جرام',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'مطلوب';
                if (double.tryParse(value) == null) return 'رقم غير صحيح';
                return null;
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['tons'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'طن',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'مطلوب';
                final tons = double.tryParse(value);
                if (tons == null) return 'رقم غير صحيح';
                if (tons <= 0) return 'يجب أن يكون أكبر من 0';
                return null;
              },
              onChanged: (_) => _calculateRow(idx),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: row['qty'],
              readOnly: true,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                fillColor: Colors.grey.shade200,
                filled: true,
                border: const OutlineInputBorder(),
                hintText: 'بكرة',
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
          // ✅ في وضع التعديل، نسمح بحذف أي صف مع بقاء صف واحد على الأقل
          if (isEditing || !isEditing)
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                if (_orderRows.length > 1) {
                  setState(() => _orderRows.removeAt(idx));
                } else {
                  _showSnackBar('لا يمكن حذف الصف الأخير');
                }
              },
              tooltip: 'حذف هذا السطر',
            ),
        ],
      ),
    );
  }

  Future<void> _handleSave(bool isEditing) async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('برجاء تصحيح الأخطاء الظاهرة', isError: false);
      return;
    }

    for (int i = 0; i < _orderRows.length; i++) {
      final row = _orderRows[i];
      if (row['salesOrder'].text.trim().isEmpty) {
        _showSnackBar('رقم أمر البيع في السطر ${i + 1} مطلوب');
        return;
      }
      if (row['width'].text.trim().isEmpty || double.tryParse(row['width'].text) == null) {
        _showSnackBar('العرض في السطر ${i + 1} غير صحيح');
        return;
      }
      if (row['grams'].text.trim().isEmpty || double.tryParse(row['grams'].text) == null) {
        _showSnackBar('الجرام في السطر ${i + 1} غير صحيح');
        return;
      }
      if (row['tons'].text.trim().isEmpty || double.tryParse(row['tons'].text) == null) {
        _showSnackBar('الطن في السطر ${i + 1} غير صحيح');
        return;
      }
      if (row['qty'].text.trim().isEmpty || int.tryParse(row['qty'].text) == null) {
        _showSnackBar('الكمية في السطر ${i + 1} غير صحيحة (تأكد من الحساب التلقائي)');
        return;
      }
    }

    try {
      List<Order> ordersToSave = [];
      for (var row in _orderRows) {
        ordersToSave.add(Order(
          id: isEditing ? widget.order!.id : null,
          date: isEditing ? widget.order!.date : DateTime.now(),
          customerName: _customerController.text.trim(),
          salesOrder: row['salesOrder'].text.trim(),
          width: double.parse(row['width'].text),
          quantity: int.parse(row['qty'].text),
          grams: double.tryParse(row['grams'].text) ?? 0,
          totalTons: double.parse(row['tons'].text),
          diameter: row['diameter'],
          diameterWeight: _diameterSpecs[row['diameter']]!,
          status: 'انتظار',   // ببساطة، دائمًا انتظار
          plannedQuantity: 0, // دائمًا صفر، لأن الإضافة والتعديل يحتاجان بداية جديدة
        ));
      }

      await context.read<OrdersCubit>().saveOrders(ordersToSave, isEditing);
      if (context.mounted) {
        Navigator.pop(context, true); // ✅ إرجاع true عند النجاح
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء الحفظ: $e');
      if (context.mounted) Navigator.pop(context, false); // ❌ إرجاع false عند الفشل
    }
  }
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.orange,
      ),
    );
  }
}