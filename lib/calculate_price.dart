import 'dart:convert';

import 'package:eco_move_frontend/routes/frontend_routes.dart';
import 'package:flutter/material.dart';
import 'package:eco_move_frontend/l10n/context_ext.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChargeCalculatorScreen extends StatefulWidget {
  final List<dynamic> tipoCarga;

  const ChargeCalculatorScreen({
    super.key,
    required this.tipoCarga,
  });

  @override
  ChargeCalculatorScreenState createState() => ChargeCalculatorScreenState();
}

class ChargeCalculatorScreenState extends State<ChargeCalculatorScreen> {
  final TextEditingController batteryCapacityController =
  TextEditingController();
  final TextEditingController currentPercentageController =
  TextEditingController();
  final TextEditingController desiredPercentageController =
  TextEditingController();

  double? pricePerKWh = -1;
  bool isLoadingPrice = true;
  bool isCalculating = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchPrice();
  }

  void _showPriceDialog(double price) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.euro,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                context.loc.calc_price_title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${context.loc.calc_price_total_is}: €${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchPrice() async {
    setState(() {
      isLoadingPrice = true;
    });

    final url = Uri.parse(
      FrontendRoutes.build(
        FrontendRoutes.price,
      ),
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String decodedResponse = utf8.decode(response.bodyBytes);
        Map<String, dynamic> data = jsonDecode(decodedResponse);
        print(data);
        DateTime now = DateTime.now();
        DateTime roundedHour = DateTime(now.year, now.month, now.day, now.hour);
        String formattedTime = DateFormat.Hm().format(roundedHour);
        print('formatted ${formattedTime}');

        List<dynamic> preciosHoy = data["precios_hoy"];

        print(preciosHoy);

        for (var item in preciosHoy) {
          if (item["hora"] == formattedTime) {
            setState(() {
              pricePerKWh = item["precio_kwh"];
              isLoadingPrice = false;
            });
            break;
          }
        }
      } else {
        print('Error: Received status code ${response.statusCode}');
        setState(() {
          isLoadingPrice = false;
        });
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      setState(() {
        isLoadingPrice = false;
      });
    }
  }

  void _calculatePrice() async {
    setState(() {
      isCalculating = true;
    });

    // Add a small delay to show the loading state
    await Future.delayed(const Duration(milliseconds: 500));

    double batteryCapacity =
        double.tryParse(batteryCapacityController.text) ?? 0;
    double currentPercentage =
        double.tryParse(currentPercentageController.text) ?? 0;
    double desiredPercentage =
        double.tryParse(desiredPercentageController.text) ?? 0;

    if (batteryCapacity <= 0) {
      setState(() {
        isCalculating = false;
      });
      _showErrorSnackBar(context.loc.calc_error_capacity);
      return;
    }

    if (currentPercentage < 0 ||
        currentPercentage > 100 ||
        desiredPercentage < 0 ||
        desiredPercentage > 100 ||
        desiredPercentage <= currentPercentage) {
      setState(() {
        isCalculating = false;
      });
      _showErrorSnackBar(context.loc.calc_error_percentages);
      return;
    }

    if (pricePerKWh != null && pricePerKWh! > 0) {
      double energyRequired =
          (desiredPercentage - currentPercentage) / 100 * batteryCapacity;
      double price = energyRequired * pricePerKWh!;

      setState(() {
        isCalculating = false;
      });
      _showPriceDialog(price);
    } else {
      setState(() {
        isCalculating = false;
      });
      _showErrorSnackBar(context.loc.calc_error_no_price);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    batteryCapacityController.dispose();
    currentPercentageController.dispose();
    desiredPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(context.loc.calc_price_title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05, // 5% padding
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.loc.calc_type,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.tipoCarga
                            .map((tipo) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            tipo,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.euro,
                              color: Colors.green.shade600,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${context.loc.calc_price}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isLoadingPrice)
                          Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.loc.station_loading,
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            pricePerKWh != null && pricePerKWh! > 0
                                ? '€${pricePerKWh!.toStringAsFixed(2)} / kWh'
                                : context.loc.calc_error_no_price,
                            style: TextStyle(
                              color: pricePerKWh != null && pricePerKWh! > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Input Fields
            _buildInputField(
              context.loc.calc_capacity_label,
              batteryCapacityController,
              'Ej: 60',
              Icons.battery_charging_full,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              context.loc.calc_current_label,
              currentPercentageController,
              'Ej: 20',
              Icons.battery_2_bar,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              context.loc.calc_target_label,
              desiredPercentageController,
              'Ej: 80',
              Icons.battery_full,
            ),
            const SizedBox(height: 32),

            // Calculate Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: isCalculating || isLoadingPrice ? null : _calculatePrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isCalculating
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Calculando...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
                    : Text(
                  context.loc.calc_button,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      String hintText,
      IconData icon,
      ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}