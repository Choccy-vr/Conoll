import 'package:conoll/services/classes/Conoll_Class.dart';
import 'package:conoll/services/classes/class_service.dart';
import 'package:conoll/services/navigation/navigation_service.dart';
import 'package:conoll/services/subjects/Conoll_Subject.dart';
import 'package:conoll/services/subjects/subject_service.dart';
import 'package:flutter/material.dart';
import '/services/supabase/auth/Auth.dart';

class SignUpProfilePage extends StatefulWidget {
  const SignUpProfilePage({super.key});

  @override
  State<SignUpProfilePage> createState() => _SignUpProfilePageState();
}

class _SignUpProfilePageState extends State<SignUpProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  late int _selectedGradeNum;
  String _selectedGrade = '9th Grade';
  final List<String> _grades = [
    '9th Grade',
    '10th Grade',
    '11th Grade',
    '12th Grade',
  ];

  int _getGradeNumber(String grade) {
    switch (grade) {
      case '9th Grade':
        return 9;
      case '10th Grade':
        return 10;
      case '11th Grade':
        return 11;
      case '12th Grade':
        return 12;
      default:
        return 9;
    }
  }

  final List<Conoll_Class> _selectedClasses = [];
  Conoll_Subject? _selectedSubject;
  List<Conoll_Subject> _availableSubjects = [];
  List<Conoll_Class> _availablePeriods = [];
  bool _showPeriodSelection = false;
  bool _showSubjectCreation = false;
  bool _showClassCreation = false;

  // Subject creation form controllers
  final _subjectNameController = TextEditingController();
  final _subjectTeacherController = TextEditingController();
  final _subjectCreationFormKey = GlobalKey<FormState>();

  // Class creation form controllers
  final _periodController = TextEditingController();
  final _classCreationFormKey = GlobalKey<FormState>();
  Conoll_Subject? _selectedSubjectForClass;

  @override
  void initState() {
    super.initState();
    _selectedGradeNum = _getGradeNumber(_selectedGrade);
    _loadSubjects(_selectedGradeNum);
  }

  Future<void> _loadSubjects(int grade) async {
    try {
      final subjects = await SubjectService.getSubjectsInAGrade(grade);
      setState(() {
        _availableSubjects = subjects;
      });
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  Future<void> _loadPeriodsForSubject(int subject) async {
    try {
      final classes = await ClassService.getClassesForSubject(subject);
      setState(() {
        _availablePeriods = classes;
        _showPeriodSelection = true;
      });
    } catch (e) {
      print('Error loading periods: $e');
    }
  }

  // Validation methods
  bool _isSubjectNameTaken(String name) {
    return _availableSubjects.any(
          (subject) => subject.name.toLowerCase() == name.toLowerCase(),
        ) ||
        _selectedClasses.any((classInfo) {
          final subject = _availableSubjects.firstWhere(
            (s) => int.tryParse(s.id) == classInfo.subjectId,
            orElse: () => Conoll_Subject(
              id: '0',
              name: '',
              teacher: '',
              students: [],
              grade: 0,
              room: 0,
            ),
          );
          return subject.name.toLowerCase() == name.toLowerCase();
        });
  }

  bool _isClassAlreadySelected(int subjectId, int period) {
    return _selectedClasses.any(
      (classInfo) =>
          classInfo.subjectId == subjectId && classInfo.period == period,
    );
  }

  bool _isPeriodTaken(int period) {
    return _selectedClasses.any((classInfo) => classInfo.period == period);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _subjectNameController.dispose();
    _subjectTeacherController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _handleCompleteSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClasses.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select exactly 8 classes (currently have ${_selectedClasses.length})',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Authentication.CreateProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        grade: _getGradeNumber(_selectedGrade),
        classes: _selectedClasses,
      );

      if (mounted) {
        NavigationService.navigateTo(
          context: context,
          destination: AppDestination.home,
          colorScheme: Theme.of(context).colorScheme,
          textTheme: Theme.of(context).textTheme,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account creation failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    _buildNameField(context),
                    const SizedBox(height: 16),
                    _buildUsernameField(context),
                    const SizedBox(height: 16),
                    _buildGradeDropdown(context),
                    const SizedBox(height: 16),
                    _buildClassesSection(context),
                    const SizedBox(height: 32),
                    _buildCompleteButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.person_outline,
            size: 48,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Almost Done!',
          style: textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete your profile to finish setting up your account',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: const Icon(Icons.person_outlined),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your full name';
        }
        if (value.trim().split(' ').length < 2) {
          return 'Please enter your first and last name';
        }
        return null;
      },
    );
  }

  Widget _buildUsernameField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: _usernameController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Username',
        hintText: 'Choose a unique username',
        prefixIcon: const Icon(Icons.alternate_email),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a username';
        }
        if (value.length < 3) {
          return 'Username must be at least 3 characters';
        }
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
          return 'Username can only contain letters, numbers, and underscores';
        }
        return null;
      },
    );
  }

  Widget _buildGradeDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      value: _selectedGrade,
      decoration: InputDecoration(
        labelText: 'Grade',
        prefixIcon: const Icon(Icons.school_outlined),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      items: _grades.map((grade) {
        return DropdownMenuItem(value: grade, child: Text(grade));
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        final newGradeNum = _getGradeNumber(value);
        setState(() {
          _selectedGrade = value;
          _selectedGradeNum = newGradeNum;
          _selectedSubject = null;
          _availableSubjects = [];
          _availablePeriods = [];
          _showPeriodSelection = false;
          _showSubjectCreation = false;
          _showClassCreation = false;
        });
        _loadSubjects(newGradeNum);
      },
    );
  }

  Widget _buildClassesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Your Classes',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the classes you are currently taking',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Selected classes display
        if (_selectedClasses.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Classes (${_selectedClasses.length}/8)',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_selectedClasses.length < 8)
                Text(
                  'Need ${8 - _selectedClasses.length} more',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedClasses.map((classInfo) {
              final subject = _availableSubjects.firstWhere(
                (s) => int.tryParse(s.id) == classInfo.subjectId,
                orElse: () => Conoll_Subject(
                  id: '0',
                  name: 'Unknown',
                  teacher: 'Unknown',
                  students: [],
                  grade: 0,
                  room: 0,
                ),
              );
              return Chip(
                label: Text('${subject.name} - Period ${classInfo.period}'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _selectedClasses.remove(classInfo);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Add class section - only show if less than 8 classes
        if (_selectedClasses.length < 8) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showSubjectCreation
                  ? _buildSubjectCreation(context)
                  : _showClassCreation
                  ? _buildClassCreation(context)
                  : !_showPeriodSelection
                  ? _buildSubjectSelection(context)
                  : _buildPeriodSelection(context),
            ),
          ),
        ] else ...[
          // Show completion message when 8 classes are selected
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Perfect! You have selected all 8 required classes.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: _isLoading ? null : _handleCompleteSignUp,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : const Text(
              'Complete Setup',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildSubjectSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _showSubjectCreation = true;
                _showPeriodSelection = false;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Create Subject',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Subject',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Conoll_Subject>(
            value: _selectedSubject,
            hint: const Text('Choose a subject'),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: _availableSubjects.map((subject) {
              return DropdownMenuItem(
                value: subject,
                child: Text(subject.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedSubject = value;
                });
                final parsedId = int.tryParse(value.id);
                if (parsedId != null) {
                  print(parsedId);
                  _loadPeriodsForSubject(parsedId);
                } else {
                  // Fallback: show error if subject id isn't numeric
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid subject id')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedSubject = null;
                    _showPeriodSelection = false;
                    _showSubjectCreation = false;
                    _showClassCreation = false;
                    _availablePeriods.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showPeriodSelection = false;
                    _showSubjectCreation = false;
                    _showClassCreation = false;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                iconSize: 20,
              ),
              Expanded(
                child: Text(
                  'Select Period for ${_selectedSubject?.name ?? ""}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_availablePeriods.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    'No periods available for this subject',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSubjectForClass = _selectedSubject;
                        _showClassCreation = true;
                        _showPeriodSelection = false;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Period',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedSubjectForClass = _selectedSubject;
                  _showClassCreation = true;
                  _showPeriodSelection = false;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Period',
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._availablePeriods.map((period) {
              final subject = _availableSubjects.firstWhere(
                (s) => int.tryParse(s.id) == period.subjectId,
                orElse: () => Conoll_Subject(
                  id: '0',
                  name: 'Unknown',
                  teacher: 'Unknown',
                  students: [],
                  grade: 0,
                  room: 0,
                ),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Period ${period.period}'),
                  subtitle: Text(
                    '${subject.teacher} • ${period.students.length} students',
                  ),
                  trailing: Icon(Icons.add_circle, color: colorScheme.primary),
                  onTap: () {
                    setState(() {
                      _selectedClasses.add(period);
                      _selectedSubject = null;
                      _showPeriodSelection = false;
                      _showSubjectCreation = false;
                      _showClassCreation = false;
                      _availablePeriods.clear();
                    });
                  },
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectCreation(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _subjectCreationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSubjectCreation = false;
                      _subjectNameController.clear();
                      _subjectTeacherController.clear();
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 20,
                ),
                Expanded(
                  child: Text(
                    'Create Subject',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subject Name Field
            TextFormField(
              controller: _subjectNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                hintText: 'e.g., Advanced Biology, AP Chemistry',
                prefixIcon: const Icon(Icons.book_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject name';
                }
                if (value.trim().length < 2) {
                  return 'Subject name must be at least 2 characters';
                }
                if (_isSubjectNameTaken(value.trim())) {
                  return 'This subject name is already taken';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teacher Name Field
            TextFormField(
              controller: _subjectTeacherController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Teacher Name',
                hintText: 'e.g., Mr. Smith, Ms. Johnson',
                prefixIcon: const Icon(Icons.person_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the teacher name';
                }
                if (value.trim().length < 2) {
                  return 'Teacher name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showSubjectCreation = false;
                        _subjectNameController.clear();
                        _subjectTeacherController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleCreateSubject,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Create Subject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateSubject() async {
    if (!_subjectCreationFormKey.currentState!.validate()) return;

    try {
      final newSubject = await SubjectService.createSubject(
        name: _subjectNameController.text.trim(),
        teacher: _subjectTeacherController.text.trim(),
        grade: _selectedGradeNum,
      );

      setState(() {
        // Add the custom subject to available subjects
        _availableSubjects.add(newSubject);

        // Set as selected subject and move to class creation
        _selectedSubjectForClass = newSubject;
        _showSubjectCreation = false;
        _showClassCreation = true;

        // Clear form
        _subjectNameController.clear();
        _subjectTeacherController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Subject "${newSubject.name}" created! Now create a class for it.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating subject: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildClassCreation(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final subjectForClass = _selectedSubjectForClass ?? _selectedSubject;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _classCreationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showClassCreation = false;
                      _selectedSubjectForClass = null;
                      _periodController.clear();
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 20,
                ),
                Expanded(
                  child: Text(
                    'Create Class',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected Subject Display
            if (subjectForClass != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subjectForClass.name,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Teacher: ${subjectForClass.teacher}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Period Field
            TextFormField(
              controller: _periodController,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Period',
                hintText: 'e.g., 1, 2, 3',
                prefixIcon: const Icon(Icons.schedule_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a period number';
                }
                final period = int.tryParse(value.trim());
                if (period == null) {
                  return 'Period must be a valid number';
                }
                if (period < 1 || period > 10) {
                  return 'Period must be between 1 and 10';
                }
                if (_isPeriodTaken(period)) {
                  return 'You already have a class in period $period';
                }
                if (subjectForClass != null) {
                  final subjectId = int.tryParse(subjectForClass.id) ?? 0;
                  if (_isClassAlreadySelected(subjectId, period)) {
                    return 'You already have this subject in period $period';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showClassCreation = false;
                        _selectedSubjectForClass = null;
                        _periodController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _handleCreateClass,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Class'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateClass() async {
    if (!_classCreationFormKey.currentState!.validate()) return;

    try {
      final subjectForClass = _selectedSubjectForClass ?? _selectedSubject;
      if (subjectForClass == null) {
        throw Exception('No subject selected for class creation');
      }

      final createdClass = await ClassService.CreateClass(
        period: int.parse(_periodController.text.trim()),
        subjectId: int.parse(subjectForClass.id),
      );

      setState(() {
        // Add the class to selected classes
        _selectedClasses.add(createdClass);

        // Reset the view and clear form
        _showClassCreation = false;
        _selectedSubject = null;
        _selectedSubjectForClass = null;
        _periodController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added ${subjectForClass.name} - Period ${createdClass.period}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating class: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
