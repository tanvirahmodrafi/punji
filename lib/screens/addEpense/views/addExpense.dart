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
import 'package:supabase_flutter/supabase_flutter.dart';
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
  TextEditingController partnerShareController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  Category? selectedCategory;
  ExpenseConnection? acceptedConnection;
  Map<String, String?>? partnerProfile;
  bool isSplitEnabled = false;

  bool get isEditing => widget.existingExpense != null;

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  bool get _editingSplit => widget.existingExpense?.isSplit == true;

  String? get _connectedPartnerId {
    if (acceptedConnection == null || _currentUserId == null) {
      return null;
    }
    return acceptedConnection!.partnerIdFor(_currentUserId!);
  }

  int get _typedTotal => int.tryParse(expenseController.text) ?? 0;

  int get _typedPartnerShare => int.tryParse(partnerShareController.text) ?? 0;

  int get _typedMyShare => _typedTotal - _typedPartnerShare;

  List<String> myCategoryIcons = [
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
    'Loan',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      final splitTotal =
          e.splitTotalAmount ?? (e.amount + (e.splitShareAmount ?? 0));
      expenseController.text =
          e.isSplit ? splitTotal.toString() : e.amount.toString();
      partnerShareController.text =
          e.isSplit ? (e.splitShareAmount ?? 0).toString() : '';
      selectedCategory = e.category;
      categoryController.text = e.category.name;
      selectedDate = e.date;
      dateController.text = DateFormat('dd/MM/yyyy').format(e.date);
      isSplitEnabled = e.isSplit;
    } else {
      dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    _loadAcceptedConnection();
  }

  @override
  void dispose() {
    expenseController.dispose();
    categoryController.dispose();
    dateController.dispose();
    partnerShareController.dispose();
    super.dispose();
  }

  Future<void> _loadAcceptedConnection() async {
    try {
      final repo = context.read<ExpenseRepository>();
      final connection = await repo.getAcceptedConnection();
      Map<String, String?>? profile;
      final myUserId = _currentUserId;
      if (connection != null && myUserId != null) {
        final partnerId = connection.partnerIdFor(myUserId);
        profile = await repo.getUserProfileSummary(partnerId);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        acceptedConnection = connection;
        partnerProfile = profile;
      });
    } catch (_) {
      // Keep split feature hidden when connection info can't be loaded.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFillColor = isDark ? const Color(0xFF1B2029) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1A1F28) : Colors.white;
    final hintColor = Theme.of(
      context,
    ).colorScheme.outline.withValues(alpha: 0.55);

    return BlocListener<CreateExpenseBloc, CreateExpenseState>(
      listener: (context, state) {
        if (state is CreateExpenseSuccess) {
          Navigator.pop(context);
        } else if (state is CreateExpenseFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDark
                                ? [
                                  const Color(0xFF1E293B),
                                  const Color(0xFF111827),
                                ]
                                : [
                                  const Color(0xFFEAF4FF),
                                  const Color(0xFFF4EEFF),
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Expense' : 'Add Expense',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Capture spending quickly and keep budgets clear',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: expenseController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (isSplitEnabled) {
                        setState(() {});
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      prefixIcon: Icon(
                        FontAwesomeIcons.wallet,
                        size: 16,
                        color: hintColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      hintText: isSplitEnabled ? 'Total amount' : 'Amount',
                      hintStyle: TextStyle(
                        color: hintColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (acceptedConnection != null || _editingSplit)
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile.adaptive(
                        value: isSplitEnabled,
                        title: const Text('Split this expense'),
                        subtitle: Text(
                          acceptedConnection != null
                              ? 'Connected partner available'
                              : 'Editing existing split expense',
                        ),
                        onChanged: (value) {
                          setState(() {
                            isSplitEnabled = value;
                          });
                        },
                      ),
                    ),
                  if (isSplitEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Partner',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            partnerProfile?['fullName']?.isNotEmpty == true
                                ? partnerProfile!['fullName']!
                                : (partnerProfile?['email']?.isNotEmpty == true
                                    ? partnerProfile!['email']!
                                    : (widget.existingExpense?.splitPartnerId ??
                                        'No connected partner found')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: partnerShareController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: inputFillColor,
                        prefixIcon: Icon(
                          FontAwesomeIcons.userGroup,
                          size: 16,
                          color: hintColor,
                        ),
                        hintText: 'Partner share amount',
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your share: $_typedMyShare',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: categoryController,
                    textAlignVertical: TextAlignVertical.center,
                    readOnly: true,
                    onTap: () {
                      _showCategorySelectionDialog();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      prefixIcon:
                          selectedCategory != null
                              ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  'assets/${selectedCategory!.icon}.png',
                                  width: 24,
                                  height: 24,
                                ),
                              )
                              : Icon(
                                FontAwesomeIcons.list,
                                size: 16,
                                color: hintColor,
                              ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _showCreateCategoryDialog();
                        },
                        icon: Icon(
                          FontAwesomeIcons.plus,
                          size: 16,
                          color: hintColor,
                        ),
                      ),
                      hintText: "Enter category",
                      hintStyle: TextStyle(
                        color: hintColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      fillColor: inputFillColor,
                      prefixIcon: Icon(
                        FontAwesomeIcons.clock,
                        size: 16,
                        color: hintColor,
                      ),
                      hintText: "Date",
                      hintStyle: TextStyle(
                        color: hintColor,
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
                  SizedBox(
                    width: double.infinity,
                    height: kToolbarHeight,
                    child: BlocBuilder<CreateExpenseBloc, CreateExpenseState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed:
                              state is CreateExpenseLoading
                                  ? null
                                  : () {
                                    if (expenseController.text.isEmpty ||
                                        selectedCategory == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please fill all fields',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final typedAmount =
                                        int.tryParse(expenseController.text) ??
                                        0;
                                    if (typedAmount <= 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Amount must be greater than 0',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final existingSplit =
                                        widget.existingExpense;
                                    final currentUserId = _currentUserId;
                                    final partnerUserId =
                                        _connectedPartnerId ??
                                        existingSplit?.splitPartnerId;

                                    if (isSplitEnabled) {
                                      final partnerShare =
                                          int.tryParse(
                                            partnerShareController.text,
                                          ) ??
                                          0;
                                      if (partnerShare <= 0 ||
                                          partnerShare > typedAmount) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Partner share must be > 0 and <= total amount',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final myShare =
                                          typedAmount - partnerShare;
                                      if (myShare <= 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Your share must be greater than 0',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      if (partnerUserId == null ||
                                          partnerUserId.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'No connected partner found for splitting',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final expense = Expense(
                                        expenseId:
                                            isEditing
                                                ? widget
                                                    .existingExpense!
                                                    .expenseId
                                                : const Uuid().v1(),
                                        category: selectedCategory!,
                                        date: selectedDate,
                                        amount: myShare,
                                        isSplit: true,
                                        splitGroupId:
                                            existingSplit?.splitGroupId,
                                        splitCreatedBy:
                                            existingSplit?.splitCreatedBy ??
                                            currentUserId,
                                        splitPartnerId: partnerUserId,
                                        splitTotalAmount: typedAmount,
                                        splitShareAmount: partnerShare,
                                        userId: currentUserId,
                                      );

                                      if (isEditing) {
                                        context.read<CreateExpenseBloc>().add(
                                          UpdateSplitExpense(
                                            expense: expense,
                                            totalAmount: typedAmount,
                                            partnerShareAmount: partnerShare,
                                          ),
                                        );
                                      } else {
                                        context.read<CreateExpenseBloc>().add(
                                          CreateSplitExpense(
                                            expense: expense,
                                            partnerUserId: partnerUserId,
                                            totalAmount: typedAmount,
                                            partnerShareAmount: partnerShare,
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    if (isEditing && _editingSplit) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Split expense can only be updated as split.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final expense = Expense(
                                      expenseId:
                                          isEditing
                                              ? widget
                                                  .existingExpense!
                                                  .expenseId
                                              : const Uuid().v1(),
                                      category: selectedCategory!,
                                      date: selectedDate,
                                      amount: typedAmount,
                                      isSplit: false,
                                    );
                                    if (isEditing) {
                                      context.read<CreateExpenseBloc>().add(
                                        UpdateExpense(expense),
                                      );
                                    } else {
                                      context.read<CreateExpenseBloc>().add(
                                        CreateExpense(expense),
                                      );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? const Color(0xFF2D3748) : Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              state is CreateExpenseLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Save',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
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
                          tileColor: Color(
                            int.tryParse(categories[i].color) ?? 0xFFFFFFFF,
                          ),
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
                          borderRadius:
                              isExpended
                                  ? const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  )
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
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
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
                                        color:
                                            iconSelected == myCategoryIcons[i]
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/${myCategoryIcons[i]}.png',
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                          this.context.read<GetCategoryBloc>().add(
                            GetCategories(),
                          );
                          Navigator.pop(ctx);
                        } else if (state is CreateCategoryFailure) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to save category: ${state.error}',
                              ),
                            ),
                          );
                        }
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () {
                            if (categoryNameController.text.isEmpty ||
                                iconSelected.isEmpty) {
                              return;
                            }
                            final category = Category(
                              categoryId: const Uuid().v1(),
                              name: categoryNameController.text,
                              totalExpenses: 0,
                              icon: iconSelected,
                              color: categoryColor.toARGB32().toString(),
                            );
                            context.read<CreateCategoryBloc>().add(
                              CreateCategory(category),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontSize: 22, color: Colors.white),
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
