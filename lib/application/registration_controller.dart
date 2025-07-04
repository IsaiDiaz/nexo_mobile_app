import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexo/model/registration_data.dart';
import 'package:nexo/data/auth_repository.dart';
import 'package:pocketbase/pocketbase.dart';

class RegistrationState {
  final RegistrationStep currentStep;
  final RegistrationData registrationData;
  final bool isLoading;
  final String? errorMessage;

  RegistrationState({
    required this.currentStep,
    required this.registrationData,
    this.isLoading = false,
    this.errorMessage,
  });

  RegistrationState copyWith({
    RegistrationStep? currentStep,
    RegistrationData? registrationData,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      registrationData: registrationData ?? this.registrationData,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RegistrationController extends StateNotifier<RegistrationState> {
  final AuthRepository _authRepository;

  RegistrationController(this._authRepository)
    : super(
        RegistrationState(
          currentStep: RegistrationStep.none,
          registrationData: RegistrationData.empty(),
        ),
      );

  void selectRole(UserRole role) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(role: role),
      currentStep: RegistrationStep.userRegistration,
    );
    print('Rol seleccionado: ${role.name}. Pasando a UserRegistration.');
  }

  void setUserRegistrationData({
    required String email,
    required String password,
    required String username,
    String? avatarPath,
  }) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(
        email: email,
        password: password,
        username: username,
        avatarPath: avatarPath,
      ),
      currentStep: RegistrationStep.personDetails,
    );
    print('Datos de usuario guardados. Pasando a PersonDetails.');
  }

  void setPersonDetailsData({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    required String identificationNumber,
  }) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        identificationNumber: identificationNumber,
      ),
      currentStep: state.registrationData.role == UserRole.professional
          ? RegistrationStep.professionalProfile
          : RegistrationStep.completed,
    );
    print('Datos personales guardados. Pasando a ${state.currentStep}.');
  }

  Future<String?> setProfessionalProfileData({
    required double hourlyRate,
    required String address,
    required String description,
    required String businessName,
    required double coordinateLat,
    required double coordinateLon,
    required String category,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedData = state.registrationData.copyWith(
        hourlyRate: hourlyRate,
        address: address,
        description: description,
        businessName: businessName,
        coordinateLat: coordinateLat,
        coordinateLon: coordinateLon,
        category: category,
      );

      final errorMessage = await _finalizeRegistration(updatedData);
      if (errorMessage == null) {
        state = state.copyWith(
          currentStep: RegistrationStep.completed,
          isLoading: false,
        );
        print('Registro profesional finalizado con éxito.');
      } else {
        state = state.copyWith(isLoading: false, errorMessage: errorMessage);
        print('Error al finalizar registro profesional: $errorMessage');
      }
      return errorMessage;
    } catch (e) {
      final errorMsg = 'Error inesperado al configurar perfil profesional: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      print(errorMsg);
      return errorMsg;
    }
  }

  Future<String?> finalizeClientRegistration() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final errorMessage = await _finalizeRegistration(state.registrationData);
      if (errorMessage == null) {
        state = state.copyWith(
          currentStep: RegistrationStep.completed,
          isLoading: false,
        );
        print('Registro de cliente finalizado con éxito.');
      } else {
        state = state.copyWith(isLoading: false, errorMessage: errorMessage);
        print('Error al finalizar registro de cliente: $errorMessage');
      }
      return errorMessage;
    } catch (e) {
      final errorMsg = 'Error inesperado al finalizar registro de cliente: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      print(errorMsg);
      return errorMsg;
    }
  }

  Future<String?> _finalizeRegistration(RegistrationData data) async {
    try {
      final userRecord = await _authRepository.signUpWithProfile(
        email: data.email!,
        password: data.password!,
        username: data.username!,
        role: data.role!.name.toUpperCase(),
        avatarPath: data.avatarPath,
      );

      if (userRecord == null) {
        return "No se pudo crear el usuario base.";
      }

      final userId = userRecord.id;

      await _authRepository.createPersonProfile(
        userId: userId,
        firstName: data.firstName!,
        lastName: data.lastName!,
        phoneNumber: data.phoneNumber,
        identificationNumber: data.identificationNumber!,
      );

      if (data.role == UserRole.professional) {
        await _authRepository.createProfessionalProfile(
          userId: userId,
          hourlyRate: data.hourlyRate!,
          address: data.address!,
          description: data.description!,
          businessName: data.businessName!,
          coordinateLat: data.coordinateLat!,
          coordinateLon: data.coordinateLon!,
          category: data.category!,
        );
      }

      return null;
    } on ClientException catch (e) {
      print('PocketBase ClientException al finalizar registro: ${e.response}');
      return e.response['message']?.toString();
    } on Exception catch (e) {
      print('Excepción general al finalizar registro: $e');
      return e.toString();
    } finally {}
  }

  void resetRegistration() {
    state = RegistrationState(
      currentStep: RegistrationStep.roleSelection,
      registrationData: RegistrationData.empty(),
    );
    print('Proceso de registro reiniciado.');
  }
}

final registrationControllerProvider =
    StateNotifierProvider.autoDispose<
      RegistrationController,
      RegistrationState
    >((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return RegistrationController(authRepository);
    });
