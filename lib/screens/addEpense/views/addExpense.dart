import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:punji/screens/addEpense/blocs/create_category/create_category_bloc.dart';
import 'package:punji/screens/addEpense/blocs/create_expense/create_expense_bloc.dart';
import 'package:punji/screens/addEpense/blocs/get_categories/get_category_bloc.dart';
import 'package:uuid/uuid.dart';

class AddExpense extends StatefulWidget {
  final Expense? existingExpense;
  const AddExpense({super.key, this.existingExpense});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Category? selectedCategory;

  bool get isEditing => widget.existingExpense != null;

  List<String>myCategoryIcons = [
    'Bill',
    'education',
    'Food',
    'Gift',
    'Grocery',
    'Saloon',
    'Entertainment',
    'Pet',
    'Shopping',
    'tech',
    'Travel',
    'Sports',
    'Medicine',
    'Gyms',
    'Loan'
  ];



  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      expenseController.text = e.amount.toString();
      selectedCategory = e.category;
      categoryController.text = e.category.name;
      selectedDate = e.date;
      dateController.text = DateFormat('dd/MM/yyyy').format(e.date);
    } else {
      dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateExpenseBloc, CreateExpenseState>(
      listener: (context, state) {
        if (state is CreateExpenseSuccess) {
          Navigator.pop(context);
        } else if (state is CreateExpenseFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save expense')),
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
              Text(
                isEditing ? "Edit Expense" : "Add Expenses",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16,),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: TextFormField(
                  controller: expenseController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      FontAwesomeIcons.dollarSign,
                      size: 16,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32,),
              TextFormField(
                controller: categoryController,
                textAlignVertical: TextAlignVertical.center,
                readOnly: true,
                onTap: () {
                  _showCategorySelectionDialog();
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: selectedCategory != null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/${selectedCategory!.icon}.png',
                            width: 24,
                            height: 24,
                          ),
                        )
                      : const Icon(
                    FontAwesomeIcons.list,
                    size: 16,
                    color: Colors.grey,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _showCreateCategoryDialog();
                    },
                    icon: const Icon(
                      FontAwesomeIcons.plus,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                  hintText: "Enter category",
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
              const SizedBox(height: 16,),
              TextFormField(
                controller: dateController,
                readOnly: true,
                textAlignVertical: TextAlignVertical.center,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? newDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );

                  if (newDate != null) {
                    setState(() {
                      dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
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
              const SizedBox(height: 32,),
              SizedBox(
                width: double.infinity,
                height: kToolbarHeight,
                child: BlocBuilder<CreateExpenseBloc, CreateExpenseState>(
                  builder: (context, state) {
                    return TextButton(
                      onPressed: state is CreateExpenseLoading
                          ? null
                          : () {
                              if (expenseController.text.isEmpty || selectedCategory == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill all fields')),
                                );
                                return;
                              }
                              final expense = Expense(
                                expenseId: isEditing
                                    ? widget.existingExpense!.expenseId
                                    : const Uuid().v1(),
                                category: selectedCategory!,
                                date: selectedDate,
                                amount: int.tryParse(expenseController.text) ?? 0,
                              );
                              if (isEditing) {
                                context.read<CreateExpenseBloc>().add(UpdateExpense(expense));
                              } else {
                                context.read<CreateExpenseBloc>().add(CreateExpense(expense));
                              }
                            },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: state is CreateExpenseLoading
                          ? const CircularProgressIndicator(color: Colors.white)
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
              )
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showCategorySelectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return BlocBuilder<GetCategoryBloc, GetCategoryState>(
          bloc: context.read<GetCategoryBloc>(),
          builder: (blocCtx, state) {
            if (state is GetCategoryLoading) {
              return const AlertDialog(
                title: Text("Select Category"),
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (state is GetCategorySuccess) {
              final categories = state.categories;
              if (categories.isEmpty) {
                return AlertDialog(
                  title: const Text("Select Category"),
                  content: const Text("No categories yet. Create one first!"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showCreateCategoryDialog();
                      },
                      child: const Text("Create Category"),
                    ),
                  ],
                );
              }
              return AlertDialog(
                title: const Text("Select Category"),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: Image.asset(
                            'assets/${categories[i].icon}.png',
                            width: 30,
                            height: 30,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.category);
                            },
                          ),
                          title: Text(categories[i].name),
                          tileColor: Color(int.tryParse(categories[i].color) ?? 0xFFFFFFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onTap: () {
                            setState(() {
                              selectedCategory = categories[i];
                              categoryController.text = categories[i].name;
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  ),
                ),
              );
            }
            return const AlertDialog(
              title: Text("Select Category"),
              content: Text("Failed to load categories"),
            );
          },
        );
      },
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isExpended = false;
        String iconSelected = '';
        Color categoryColor = Colors.white;
        TextEditingController categoryNameController = TextEditingController();
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text("Create a Category"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: categoryNameController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Name",
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
                    const SizedBox(height: 20),
                    TextFormField(
                      onTap: () {
                        setDialogState(() {
                          isExpended = !isExpended;
                        });
                      },
                      textAlignVertical: TextAlignVertical.center,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        isDense: true,
                        suffixIcon: const Icon(
                          CupertinoIcons.chevron_down,
                          size: 12,
                        ),
                        fillColor: Colors.white,
                        hintText: iconSelected.isEmpty ? "Icon" : iconSelected,
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: isExpended
                              ? const BorderRadius.vertical(top: Radius.circular(12))
                              : BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    isExpended
                        ? Container(
                            width: MediaQuery.of(context).size.width,
                            height: 200,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 5,
                                  crossAxisSpacing: 5,
                                ),
                                itemCount: myCategoryIcons.length,
                                itemBuilder: (context, int i) {
                                  return GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        iconSelected = myCategoryIcons[i];
                                      });
                                    },
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          width: 3,
                                          color: iconSelected == myCategoryIcons[i]
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: AssetImage('assets/${myCategoryIcons[i]}.png'),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        : Container(),
                    const SizedBox(height: 20),
                    TextFormField(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx2) {
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ColorPicker(
                                    pickerColor: categoryColor,
                                    onColorChanged: (value) {
                                      setDialogState(() {
                                        categoryColor = value;
                                      });
                                    },
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx2);
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      textAlignVertical: TextAlignVertical.center,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        isDense: true,
                        fillColor: categoryColor,
                        hintText: "Color",
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
                    const SizedBox(height: 20),
                    BlocListener<CreateCategoryBloc, CreateCategoryState>(
                      bloc: context.read<CreateCategoryBloc>(),
                      listener: (context, state) {
                        if (state is CreateCategorySuccess) {
                          this.context.read<GetCategoryBloc>().add(GetCategories());
                          Navigator.pop(ctx);
                        } else if (state is CreateCategoryFailure) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Failed to save category: ${state.error}')),
                          );
                        }
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () {
                            if (categoryNameController.text.isEmpty || iconSelected.isEmpty) {
                              return;
                            }
                            final category = Category(
                              categoryId: const Uuid().v1(),
                              name: categoryNameController.text,
                              totalExpenses: 0,
                              icon: iconSelected,
                              color: categoryColor.toARGB32().toString(),
                            );
                            context.read<CreateCategoryBloc>().add(CreateCategory(category));
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
