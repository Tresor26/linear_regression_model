import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../widgets/section_header.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/input_field.dart';
import '../widgets/result_card.dart';

const String _apiUrl =
    'https://linear-regression-model-eeak.onrender.com/predict';

const List<String> areas = [
  'Albania', 'Algeria', 'Angola', 'Argentina', 'Armenia', 'Australia',
  'Austria', 'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Belarus',
  'Belgium', 'Botswana', 'Brazil', 'Bulgaria', 'Burkina Faso', 'Burundi',
  'Cameroon', 'Canada', 'Central African Republic', 'Chile', 'Colombia',
  'Croatia', 'Denmark', 'Dominican Republic', 'Ecuador', 'Egypt',
  'El Salvador', 'Eritrea', 'Estonia', 'Finland', 'France', 'Germany',
  'Ghana', 'Greece', 'Guatemala', 'Guinea', 'Guyana', 'Haiti', 'Honduras',
  'Hungary', 'India', 'Indonesia', 'Iraq', 'Ireland', 'Italy', 'Jamaica',
  'Japan', 'Kazakhstan', 'Kenya', 'Latvia', 'Lebanon', 'Lesotho', 'Libya',
  'Lithuania', 'Madagascar', 'Malawi', 'Malaysia', 'Mali', 'Mauritania',
  'Mauritius', 'Mexico', 'Montenegro', 'Morocco', 'Mozambique', 'Namibia',
  'Nepal', 'Netherlands', 'New Zealand', 'Nicaragua', 'Niger', 'Norway',
  'Pakistan', 'Papua New Guinea', 'Peru', 'Poland', 'Portugal', 'Qatar',
  'Romania', 'Rwanda', 'Saudi Arabia', 'Senegal', 'Slovenia', 'South Africa',
  'Spain', 'Sri Lanka', 'Sudan', 'Suriname', 'Sweden', 'Switzerland',
  'Tajikistan', 'Thailand', 'Tunisia', 'Turkey', 'Uganda', 'Ukraine',
  'United Kingdom', 'Uruguay', 'Zambia', 'Zimbabwe',
];

const List<String> crops = [
  'Cassava', 'Maize', 'Plantains and others', 'Potatoes', 'Rice, paddy',
  'Sorghum', 'Soybeans', 'Sweet potatoes', 'Wheat', 'Yams',
];

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  String? _selectedArea;
  String? _selectedCrop;

  final _yearCtrl      = TextEditingController();
  final _rainfallCtrl  = TextEditingController();
  final _pesticideCtrl = TextEditingController();
  final _tempCtrl      = TextEditingController();

  bool _isLoading = false;
  String? _resultText;
  bool _isError = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _yearCtrl.dispose();
    _rainfallCtrl.dispose();
    _pesticideCtrl.dispose();
    _tempCtrl.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _resultText = null;
    });
    _animCtrl.reset();

    final body = jsonEncode({
      'area': _selectedArea,
      'item': _selectedCrop,
      'year': int.parse(_yearCtrl.text.trim()),
      'average_rainfall_mm_per_year': double.parse(_rainfallCtrl.text.trim()),
      'pesticides_tonnes': double.parse(_pesticideCtrl.text.trim()),
      'avg_temp': double.parse(_tempCtrl.text.trim()),
    });

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final yieldVal = data['predicted_yield_hg_per_ha'] as num;
        final tonnesHa = yieldVal / 10000;
        setState(() {
          _isError = false;
          _resultText =
              '${yieldVal.toStringAsFixed(1)} hg/ha\n'
              '≈ ${tonnesHa.toStringAsFixed(2)} tonnes/ha';
        });
      } else {
        final detail = data['detail'];
        setState(() {
          _isError = true;
          _resultText = detail is String
              ? detail
              : 'Validation error — check your inputs.';
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _resultText = 'Could not reach the server.\nCheck your connection.';
      });
    } finally {
      setState(() => _isLoading = false);
      _animCtrl.forward();
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _yearCtrl.clear();
    _rainfallCtrl.clear();
    _pesticideCtrl.clear();
    _tempCtrl.clear();
    setState(() {
      _selectedArea = null;
      _selectedCrop = null;
      _resultText = null;
    });
    _animCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: const Color(0xFF2E7D32),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                title: const Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop Yield Predictor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Rwanda AgriAI Mission',
                      style: TextStyle(color: Color(0xFFA5D6A7), fontSize: 11),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 24),
                      child: Icon(Icons.eco, size: 72, color: Color(0x33FFFFFF)),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.location_on_outlined,
                        label: 'Location & Crop',
                      ),
                      const SizedBox(height: 10),
                      DropdownField(
                        label: 'Country',
                        hint: 'Select a country',
                        icon: Icons.flag_outlined,
                        value: _selectedArea,
                        items: areas,
                        onChanged: (v) => setState(() => _selectedArea = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownField(
                        label: 'Crop Type',
                        hint: 'Select a crop',
                        icon: Icons.grass,
                        value: _selectedCrop,
                        items: crops,
                        onChanged: (v) => setState(() => _selectedCrop = v),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        icon: Icons.bar_chart_outlined,
                        label: 'Agricultural Inputs',
                      ),
                      const SizedBox(height: 10),
                      InputField(
                        controller: _yearCtrl,
                        label: 'Year',
                        hint: 'e.g. 2013',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final y = int.tryParse(v);
                          if (y == null || y < 1990 || y > 2050) {
                            return 'Enter a year between 1990 and 2050';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _rainfallCtrl,
                        label: 'Average Rainfall (mm/year)',
                        hint: 'e.g. 1200.0',
                        icon: Icons.water_drop_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n < 0 || n > 5000) {
                            return 'Enter a value between 0 and 5000';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _pesticideCtrl,
                        label: 'Pesticides (tonnes)',
                        hint: 'e.g. 50.0',
                        icon: Icons.science_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n < 0) return 'Enter a valid positive number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InputField(
                        controller: _tempCtrl,
                        label: 'Average Temperature (°C)',
                        hint: 'e.g. 21.5',
                        icon: Icons.thermostat_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n < -10 || n > 50) {
                            return 'Enter a temperature between -10 and 50°C';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _predict,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(Icons.agriculture),
                          label: Text(
                            _isLoading ? 'Predicting...' : 'Predict',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Reset'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_resultText != null)
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: ResultCard(
                            text: _resultText!,
                            isError: _isError,
                            area: _selectedArea,
                            crop: _selectedCrop,
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
