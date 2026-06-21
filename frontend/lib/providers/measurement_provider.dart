import 'package:flutter/material.dart';
import '../models/body_measurement.dart';
import '../services/measurement_service.dart';

class MeasurementProvider extends ChangeNotifier {
  final MeasurementService _measurementService = MeasurementService();
  
  List<BodyMeasurement> _measurements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BodyMeasurement> get measurements => _measurements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMeasurements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _measurements = await _measurementService.getMeasurements();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeasurement(BodyMeasurement measurement) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMeasurement = await _measurementService.addMeasurement(measurement);
      // Wstawiamy nowy pomiar na początek listy (sortowanie malejące)
      _measurements.insert(0, newMeasurement);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}