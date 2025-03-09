import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tca_flutter/tca_flutter.dart';

// MARK: - Parent Feature Domain

class FormWizardState {
  PersonalInfoState personalInfo;
  ContactInfoState contactInfo;
  int currentStep;
  bool isSubmitting;

  FormWizardState({
    PersonalInfoState? personalInfo,
    ContactInfoState? contactInfo,
    this.currentStep = 0,
    this.isSubmitting = false,
  })  : personalInfo = personalInfo ?? PersonalInfoState(),
        contactInfo = contactInfo ?? ContactInfoState();

  bool get canSubmit =>
      personalInfo.isValid && contactInfo.isValid && !isSubmitting;

  Map<String, dynamic> toJson() => {
        'personalInfo': personalInfo.toJson(),
        'contactInfo': contactInfo.toJson(),
        'currentStep': currentStep,
      };

  factory FormWizardState.fromJson(Map<String, dynamic> json) =>
      FormWizardState(
        personalInfo: PersonalInfoState.fromJson(json['personalInfo']),
        contactInfo: ContactInfoState.fromJson(json['contactInfo']),
        currentStep: json['currentStep'],
      );

  @override
  String toString() =>
      'FormWizardState(personalInfo: $personalInfo, contactInfo: $contactInfo, currentStep: $currentStep, isSubmitting: $isSubmitting)';
}

sealed class FormWizardAction {
  const FormWizardAction();
}

class NextStep extends FormWizardAction {
  const NextStep();
}

class PreviousStep extends FormWizardAction {
  const PreviousStep();
}

class SubmitForm extends FormWizardAction {
  const SubmitForm();
}

class LoadSavedForm extends FormWizardAction {
  const LoadSavedForm();
}

class SaveForm extends FormWizardAction {
  const SaveForm();
}

class PersonalInfoAction extends FormWizardAction {
  final PersonalInfoFormAction action;
  const PersonalInfoAction(this.action);
}

class ContactInfoAction extends FormWizardAction {
  final ContactInfoFormAction action;
  const ContactInfoAction(this.action);
}

// MARK: - Personal Info Feature

class PersonalInfoState {
  String firstName;
  String lastName;
  String? firstNameError;
  String? lastNameError;

  PersonalInfoState({
    this.firstName = '',
    this.lastName = '',
    this.firstNameError,
    this.lastNameError,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
      };

  factory PersonalInfoState.fromJson(Map<String, dynamic> json) =>
      PersonalInfoState(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
      );

  bool get isValid =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      firstNameError == null &&
      lastNameError == null;

  @override
  String toString() =>
      'PersonalInfoState(firstName: $firstName, lastName: $lastName, firstNameError: $firstNameError, lastNameError: $lastNameError)';
}

sealed class PersonalInfoFormAction {
  const PersonalInfoFormAction();
}

class UpdateFirstName extends PersonalInfoFormAction {
  final String value;
  const UpdateFirstName(this.value);
}

class UpdateLastName extends PersonalInfoFormAction {
  final String value;
  const UpdateLastName(this.value);
}

class ValidatePersonalInfo extends PersonalInfoFormAction {
  const ValidatePersonalInfo();
}

// MARK: - Contact Info Feature

class ContactInfoState {
  String email;
  String phone;
  String? emailError;
  String? phoneError;

  ContactInfoState({
    this.email = '',
    this.phone = '',
    this.emailError,
    this.phoneError,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'phone': phone,
      };

  factory ContactInfoState.fromJson(Map<String, dynamic> json) =>
      ContactInfoState(
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
      );

  bool get isValid =>
      email.isNotEmpty &&
      phone.isNotEmpty &&
      emailError == null &&
      phoneError == null;

  @override
  String toString() =>
      'ContactInfoState(email: $email, phone: $phone, emailError: $emailError, phoneError: $phoneError)';
}

sealed class ContactInfoFormAction {
  const ContactInfoFormAction();
}

class UpdateEmail extends ContactInfoFormAction {
  final String value;
  const UpdateEmail(this.value);
}

class UpdatePhone extends ContactInfoFormAction {
  final String value;
  const UpdatePhone(this.value);
}

class ValidateContactInfo extends ContactInfoFormAction {
  const ValidateContactInfo();
}

// MARK: - Features Implementation

class FormWizard {
  static const _storageKey = 'form_wizard_state';

  static final personalInfoReducer =
      Reducer<PersonalInfoState, PersonalInfoFormAction>((state, action) {
    switch (action) {
      case UpdateFirstName(value: final value):
        state.firstName = value;
        state.firstNameError = value.isEmpty ? 'First name is required' : null;
        return Effect.none();

      case UpdateLastName(value: final value):
        state.lastName = value;
        state.lastNameError = value.isEmpty ? 'Last name is required' : null;
        return Effect.none();

      case ValidatePersonalInfo():
        state.firstNameError =
            state.firstName.isEmpty ? 'First name is required' : null;
        state.lastNameError =
            state.lastName.isEmpty ? 'Last name is required' : null;
        return Effect.none();
    }
  });

  static final contactInfoReducer =
      Reducer<ContactInfoState, ContactInfoFormAction>((state, action) {
    switch (action) {
      case UpdateEmail(value: final value):
        state.email = value;
        state.emailError = !value.contains('@') ? 'Invalid email' : null;
        return Effect.none();

      case UpdatePhone(value: final value):
        state.phone = value;
        state.phoneError =
            !RegExp(r'^\d{10}$').hasMatch(value) ? 'Invalid phone' : null;
        return Effect.none();

      case ValidateContactInfo():
        state.emailError = !state.email.contains('@') ? 'Invalid email' : null;
        state.phoneError =
            !RegExp(r'^\d{10}$').hasMatch(state.phone) ? 'Invalid phone' : null;
        return Effect.none();
    }
  });

  static final reducer =
      Reducer<FormWizardState, FormWizardAction>((state, action) {
    switch (action) {
      case LoadSavedForm():
        return Effect.publisher((send) async {
          final prefs = await SharedPreferences.getInstance();
          final jsonStr = prefs.getString(_storageKey);
          if (jsonStr != null) {
            try {
              final json = jsonDecode(jsonStr);
              final savedState = FormWizardState.fromJson(json);
              state.personalInfo = savedState.personalInfo;
              state.contactInfo = savedState.contactInfo;
              state.currentStep = savedState.currentStep;
            } catch (e) {
              // Handle error if needed
            }
          }
        });

      case SaveForm():
        return Effect.publisher((send) async {
          final prefs = await SharedPreferences.getInstance();
          final jsonStr = jsonEncode(state.toJson());
          await prefs.setString(_storageKey, jsonStr);
        });

      case NextStep():
        if (state.currentStep == 0) {
          // Validate and save personal info before moving to next step
          final personalInfoEffect = Reducer.pullback<FormWizardState,
                  FormWizardAction, PersonalInfoState, PersonalInfoFormAction>(
            child: personalInfoReducer,
            toChildState: (state) => state.personalInfo,
            fromChildState: (state, childState) =>
                state.personalInfo = childState,
            toChildAction: (_) => const ValidatePersonalInfo(),
          )
              .reduce(state, const PersonalInfoAction(ValidatePersonalInfo()))
              .effect;

          if (state.personalInfo.isValid) {
            state.currentStep++;
            // Save form after successful validation
            return Effect.merge([
              personalInfoEffect,
              Effect.send(const SaveForm()),
            ]);
          }
          return personalInfoEffect;
        }
        return Effect.none();

      case PreviousStep():
        if (state.currentStep > 0) {
          state.currentStep--;
        }
        return Effect.none();

      case SubmitForm():
        if (state.canSubmit) {
          state.isSubmitting = true;
          return Effect.publisher((send) async {
            // Simulate API call
            await Future.delayed(const Duration(seconds: 1));
            state.isSubmitting = false;
            // Clear saved form after successful submission
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_storageKey);
          });
        }
        return Effect.none();

      case PersonalInfoAction(action: final formAction):
        return Reducer.pullback<FormWizardState, FormWizardAction,
            PersonalInfoState, PersonalInfoFormAction>(
          child: personalInfoReducer,
          toChildState: (state) => state.personalInfo,
          fromChildState: (state, childState) =>
              state.personalInfo = childState,
          toChildAction: (action) => switch (action) {
            PersonalInfoAction(action: final action) => action,
            _ => null,
          },
        ).reduce(state, action).effect;

      case ContactInfoAction(action: final formAction):
        return Reducer.pullback<FormWizardState, FormWizardAction,
            ContactInfoState, ContactInfoFormAction>(
          child: contactInfoReducer,
          toChildState: (state) => state.contactInfo,
          fromChildState: (state, childState) => state.contactInfo = childState,
          toChildAction: (action) => switch (action) {
            ContactInfoAction(action: final action) => action,
            _ => null,
          },
        ).reduce(state, action).effect;
    }
  });
}

// MARK: - Feature View

class FormWizardView extends StatelessWidget {
  final Store<FormWizardState, FormWizardAction> store;

  const FormWizardView({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    // Load saved form when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.send(const LoadSavedForm());
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Wizard'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (store.state.currentStep + 1) / 2,
                ),
                const SizedBox(height: 16),
                if (store.state.currentStep == 0) _buildPersonalInfoForm(),
                if (store.state.currentStep == 1) _buildContactInfoForm(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (store.state.currentStep > 0)
                      FilledButton(
                        onPressed: () => store.send(const PreviousStep()),
                        child: const Text('Previous'),
                      ),
                    if (store.state.currentStep < 1)
                      FilledButton(
                        onPressed: () => store.send(const NextStep()),
                        child: const Text('Next'),
                      ),
                    if (store.state.currentStep == 1)
                      FilledButton(
                        onPressed: store.state.canSubmit
                            ? () => store.send(const SubmitForm())
                            : null,
                        child: store.state.isSubmitting
                            ? const CircularProgressIndicator()
                            : const Text('Submit'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    final state = store.state.personalInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'First Name',
            errorText: state.firstNameError,
          ),
          onChanged: (value) =>
              store.send(PersonalInfoAction(UpdateFirstName(value))),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Last Name',
            errorText: state.lastNameError,
          ),
          onChanged: (value) =>
              store.send(PersonalInfoAction(UpdateLastName(value))),
        ),
      ],
    );
  }

  Widget _buildContactInfoForm() {
    final state = store.state.contactInfo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: state.emailError,
          ),
          onChanged: (value) =>
              store.send(ContactInfoAction(UpdateEmail(value))),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Phone',
            errorText: state.phoneError,
            hintText: '10 digits',
          ),
          onChanged: (value) =>
              store.send(ContactInfoAction(UpdatePhone(value))),
        ),
      ],
    );
  }
}
