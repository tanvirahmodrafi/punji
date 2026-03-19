import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:punji/screens/addIncome/blocs/create_income/create_income_bloc.dart';
import 'package:uuid/uuid.dart';

class _IncomeCategoryItem {
  final String name;
  final Color color;
  final IconData icon;

  const _IncomeCategoryItem({
    required this.name,
    required this.color,
    required this.icon,
  });
}

final List<_IncomeCategoryItem> _incomeCategories = [
  _IncomeCategoryItem(
    name: 'Salary',
    color: Colors.amber,
    icon: FontAwesomeIcons.dollarSign,
  ),
  _IncomeCategoryItem(
    name: 'Business',
    color: Colors.green,
    icon: FontAwesomeIcons.dollarSign,
  ),
  _IncomeCategoryItem(
    name: 'Bank',
    color: Colors.redAccent,
    icon: FontAwesomeIcons.dollarSign,
  ),
  _IncomeCategoryItem(
    name: 'Freelance',
    color: Colors.blueAccent,
    icon: FontAwesomeIcons.dollarSign,
  ),
  _IncomeCategoryItem(
    name: 'Gift',
    color: Colors.purple,
    icon: FontAwesomeIcons.dollarSign,
  ),
  _IncomeCategoryItem(
    name: 'Other',
    color: Colors.teal,
    icon: FontAwesomeIcons.dollarSign,
  ),
];

class AddIncome extends StatefulWidget {
  final Income? existingIncome;

  const AddIncome({super.key, this.existingIncome});

  @override
  State<AddIncome> createState() => _AddIncomeState();
}

class _AddIncomeState extends State<AddIncome> {
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  int? selectedCategoryIndex;

  bool get isEditing => widget.existingIncome != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingIncome != null) {
      final inc = widget.existingIncome!;
      amountController.text = inc.amount.toString();
      selectedDate = inc.date;
      dateController.text = DateFormat('dd/MM/yyyy').format(inc.date);
      // Find matching category index
      selectedCategoryIndex = _incomeCategories.indexWhere(
        (c) => c.name == inc.category,
      );
      if (selectedCategoryIndex == -1) selectedCategoryIndex = null;
    } else {
      dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateIncomeBloc, CreateIncomeState>(
      listener: (context, state) {
        if (state is CreateIncomeSuccess) {
          Navigator.pop(context);
        } else if (state is CreateIncomeFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save income: ${state.message}')),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Add Money",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                // Amount field
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        FontAwesomeIcons.dollarSign,
                        size: 16,
                        color: Colors.grey,
                      ),
                      hintText: "Add Money",
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Category selector
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _incomeCategories.length,
                    itemBuilder: (context, index) {
                      final cat = _incomeCategories[index];
                      final isSelected = selectedCategoryIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategoryIndex = index;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: cat.color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border:
                                      isSelected
                                          ? Border.all(
                                            color: cat.color,
                                            width: 2.5,
                                          )
                                          : null,
                                ),
                                child: Icon(
                                  cat.icon,
                                  color: cat.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                  color:
                                      isSelected
                                          ? Colors.black
                                          : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Date field
                TextFormField(
                  controller: dateController,
                  readOnly: true,
                  textAlignVertical: TextAlignVertical.center,
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    DateTime? newDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (newDate != null) {
                      setState(() {
                        dateController.text = DateFormat(
                          'dd/MM/yyyy',
                        ).format(newDate);
                        selectedDate = newDate;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.clock,
                      size: 16,
                      color: Colors.grey,
                    ),
                    hintText: "Date",
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: kToolbarHeight,
                  child: BlocBuilder<CreateIncomeBloc, CreateIncomeState>(
                    builder: (context, state) {
                      return TextButton(
                        onPressed:
                            state is CreateIncomeLoading
                                ? null
                                : () {
                                  if (amountController.text.isEmpty ||
                                      selectedCategoryIndex == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please fill all fields'),
                                      ),
                                    );
                                    return;
                                  }
                                  final cat =
                                      _incomeCategories[selectedCategoryIndex!];
                                  final income = Income(
                                    incomeId:
                                        isEditing
                                            ? widget.existingIncome!.incomeId
                                            : const Uuid().v1(),
                                    category: cat.name,
                                    date: selectedDate,
                                    amount:
                                        int.tryParse(amountController.text) ??
                                        0,
                                  );
                                  context.read<CreateIncomeBloc>().add(
                                    CreateIncome(income),
                                  );
                                },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            state is CreateIncomeLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                  ),
                                ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
