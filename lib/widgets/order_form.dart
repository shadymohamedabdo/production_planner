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

  // الكنترولر والمتغير الخاصين بالتاريخ
  final _dateController = TextEditingController();
  late DateTime _selectedDate;

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
      // حالة التعديل: جلب التاريخ المسجل للأوردر وعرضه
      _selectedDate = widget.order!.date;
      _dateController.text = _selectedDate.toString().split(' ')[0];

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
      // حالة إضافة جديد: يفتح تلقائياً على تاريخ النهاردة
      _selectedDate = DateTime.now();
      _dateController.text = _selectedDate.toString().split(' ')[0];
      _addNewRow();
    }
  }

  // دالة فتح التقويم (DatePicker) لاختيار اليوم والشهر والسنة
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl, // جعل التقويم يفتح بواجهة عربية متناسقة
            child: child!,
          ),
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _selectedDate.toString().split(' ')[0];
      });
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
    _dateController.dispose();
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
    return Directionality(
      textDirection: TextDirection.rtl, // 🟢 إجبار الـ Dialog بالكامل ليعمل بالاتجاه العربي الصحيح
      child: AlertDialog(
        title: Text(isEditing ? 'تعديل الطلب' : 'إضافة أوردرات متعددة'),
        content: SizedBox(
          width: 1100,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _customerController,
                          decoration: const InputDecoration(
                            labelText: 'اسم العميل *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) =>
                          value == null || value.trim().isEmpty ? 'اسم العميل مطلوب' : null,
                        ),
                      ),
                      const SizedBox(width: 15),

                      // حقل التاريخ المطور بالكامل
                      Expanded(
                        flex: 1,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextFormField(
                            controller: _dateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'التاريخ',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                            ),
                            onTap: () => _selectDate(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  _buildTableHeader(),
                  ..._orderRows.asMap().entries.map((entry) =>
                      _buildOrderRow(entry.key, entry.value, isEditing)),
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
          // تم تبديل الترتيب ليناسب الـ RTL الطبيعي (الإلغاء يسار، الحفظ يمين)
          ElevatedButton(
            onPressed: () => _handleSave(isEditing),
            child: Text(isEditing ? 'تحديث البيانات' : 'حفظ الكل'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ],
      ),
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
        textDirection: TextDirection.rtl, // 🟢 تأكيد بدء الهيدر من اليمين
        children: const [
          SizedBox(
              width: 40,
              child: Text("م", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))
          ),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("رقم S.O", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("القطر", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("العرض", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("الجرام", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 2, child: Text("طن", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 5),
          Expanded(flex: 1, child: Text("بكر", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 40), // مساحة موازية لزر الحذف لضمان السنترة الكاملة
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
        textDirection: TextDirection.rtl, // 🟢 إجبار سطر البيانات على البدء من اليمين تماماً كالهيدر
        children: [
          // 1️⃣ رقم المسلسل (أقصى اليمين تماماً)
          SizedBox(
            width: 40,
            child: Text(
              '${idx + 1}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 5),

          // 2️⃣ رقم S.O
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['salesOrder'],
              textAlign: TextAlign.center,
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

          // 3️⃣ القطر
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<double>(
              value: row['diameter'],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              alignment: Alignment.center,
              items: _diameterSpecs.keys.map((d) {
                return DropdownMenuItem(value: d, child: Center(child: Text('$d سم')));
              }).toList(),
              onChanged: (val) {
                setState(() => row['diameter'] = val);
                _calculateRow(idx);
              },
            ),
          ),
          const SizedBox(width: 5),

          // 4️⃣ العرض
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['width'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'سم',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'مطلوب';
                if (double.tryParse(value) == null) return 'غير صحيح';
                return null;
              },
              onChanged: (_) => _calculateRow(idx),
            ),
          ),
          const SizedBox(width: 5),

          // 5️⃣ الجرام
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['grams'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'جرام',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'مطلوب';
                if (double.tryParse(value) == null) return 'غير صحيح';
                return null;
              },
            ),
          ),
          const SizedBox(width: 5),

          // 6️⃣ طن
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: row['tons'],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'طن',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'مطلوب';
                final tons = double.tryParse(value);
                if (tons == null) return 'غير صحيح';
                if (tons <= 0) return 'يجب > 0';
                return null;
              },
              onChanged: (_) => _calculateRow(idx),
            ),
          ),
          const SizedBox(width: 5),

          // 7️⃣ بكر (الخانات المحسوبة تلقائياً)
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

          // 8️⃣ زر الحذف (أقصى اليسار تماماً)
          SizedBox(
            width: 40,
            child: IconButton(
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

    try {
      List<Order> ordersToSave = [];
      for (int i = 0; i < _orderRows.length; i++) {
        final row = _orderRows[i];
        final bool isOriginalRow = isEditing && i == 0;

        ordersToSave.add(Order(
          id: isOriginalRow ? widget.order!.id : null,
          date: _selectedDate,
          customerName: _customerController.text.trim(),
          salesOrder: row['salesOrder'].text.trim(),
          width: double.parse(row['width'].text),
          quantity: int.parse(row['qty'].text),
          grams: double.tryParse(row['grams'].text) ?? 0,
          totalTons: double.parse(row['tons'].text),
          diameter: row['diameter'],
          diameterWeight: _diameterSpecs[row['diameter']]!,
          status: 'انتظار',
          plannedQuantity: 0,
        ));
      }

      await context.read<OrdersCubit>().saveOrders(ordersToSave, isEditing);
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء الحفظ: $e');
      if (context.mounted) Navigator.pop(context, false);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.orange),
    );
  }
}