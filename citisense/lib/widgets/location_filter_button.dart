import 'package:flutter/material.dart';

import '../core/location_data.dart';
import '../core/theme/app_colors.dart';

class LocationFilterButton extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  static const Map<String, List<String>> citiesAndBarangays =
      LocationData.citiesAndBarangays;

  const LocationFilterButton({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = (value != null &&
        value != 'All locations' &&
        value != 'All cities' &&
        value != 'All Cities');
    final label = active ? value! : 'All Locations';

    return InkWell(
      onTap: () => _openFilterSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.place : Icons.place_outlined,
              size: 18,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationFilterSheet(
        currentValue: value,
        onSelect: (selected) {
          if (selected == null ||
              selected == 'All locations' ||
              selected == 'All cities' ||
              selected == 'All Cities') {
            onChanged(null);
          } else {
            onChanged(selected);
          }
        },
      ),
    );
  }
}

class _LocationFilterSheet extends StatefulWidget {
  final String? currentValue;
  final ValueChanged<String?> onSelect;

  const _LocationFilterSheet({
    required this.currentValue,
    required this.onSelect,
  });

  @override
  State<_LocationFilterSheet> createState() => _LocationFilterSheetState();
}

class _LocationFilterSheetState extends State<_LocationFilterSheet> {
  final _searchController = TextEditingController();
  String? _selectedCity;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // If the current value is a city or belongs to a city, pre-select it
    if (widget.currentValue != null) {
      if (LocationFilterButton.citiesAndBarangays.containsKey(widget.currentValue)) {
        _selectedCity = widget.currentValue;
      } else {
        for (final entry in LocationFilterButton.citiesAndBarangays.entries) {
          if (entry.value.contains(widget.currentValue)) {
            _selectedCity = entry.key;
            break;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final isSearching = query.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    if (_selectedCity != null && !isSearching) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _selectedCity = null),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        isSearching
                            ? 'Search locations'
                            : _selectedCity != null
                                ? '$_selectedCity Barangays'
                                : 'Select Location',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Search city or barangay...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (text) => setState(() => _searchQuery = text),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              Expanded(
                child: isSearching
                    ? _buildSearchResults(query)
                    : _selectedCity != null
                        ? _buildBarangayList(_selectedCity!)
                        : _buildCityList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(String query) {
    final cityMatches = LocationFilterButton.citiesAndBarangays.keys
        .where((city) => city.toLowerCase().contains(query))
        .toList();

    final barangayMatches = <(String barangay, String city)>[];
    for (final entry in LocationFilterButton.citiesAndBarangays.entries) {
      for (final b in entry.value) {
        if (b.toLowerCase().contains(query)) {
          barangayMatches.add((b, entry.key));
        }
      }
    }

    if (cityMatches.isEmpty && barangayMatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 8),
              Text(
                'No matching city or barangay',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (cityMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'CITIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final city in cityMatches)
            ListTile(
              leading: Icon(Icons.location_city, color: AppColors.primary),
              title: Text(
                city,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${LocationFilterButton.citiesAndBarangays[city]?.length ?? 0} barangays',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              onTap: () {
                widget.onSelect(city);
                Navigator.pop(context);
              },
            ),
        ],
        if (barangayMatches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'BARANGAYS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final match in barangayMatches)
            ListTile(
              leading: Icon(Icons.place_outlined, color: AppColors.primary),
              title: Text(
                match.$1,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                match.$2,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              selected: widget.currentValue == match.$1,
              onTap: () {
                widget.onSelect(match.$1);
                Navigator.pop(context);
              },
            ),
        ],
      ],
    );
  }

  Widget _buildCityList() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: Icon(
            Icons.public,
            color: widget.currentValue == null ? AppColors.primary : AppColors.textMuted,
          ),
          title: const Text(
            'All Cities',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: const Text('Show complaints from all locations'),
          trailing: (widget.currentValue == null ||
                  widget.currentValue == 'All locations' ||
                  widget.currentValue == 'All cities')
              ? Icon(Icons.check, color: AppColors.primary)
              : null,
          onTap: () {
            widget.onSelect(null);
            Navigator.pop(context);
          },
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'SELECT A CITY TO VIEW BARANGAYS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final city in LocationFilterButton.citiesAndBarangays.keys)
          ListTile(
            leading: Icon(Icons.location_city, color: AppColors.primary),
            title: Text(
              city,
              style: TextStyle(
                fontWeight: widget.currentValue == city ? FontWeight.w700 : FontWeight.w600,
                color: widget.currentValue == city ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '${LocationFilterButton.citiesAndBarangays[city]?.length ?? 0} barangays',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              setState(() => _selectedCity = city);
            },
          ),
      ],
    );
  }

  Widget _buildBarangayList(String city) {
    final barangays = LocationFilterButton.citiesAndBarangays[city] ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          leading: Icon(Icons.select_all, color: AppColors.primary),
          title: Text(
            'All in $city',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('Filter all barangays in $city'),
          trailing: widget.currentValue == city
              ? Icon(Icons.check, color: AppColors.primary)
              : null,
          onTap: () {
            widget.onSelect(city);
            Navigator.pop(context);
          },
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'BARANGAYS IN $city'.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final b in barangays)
          ListTile(
            leading: Icon(
              Icons.place_outlined,
              size: 20,
              color: widget.currentValue == b ? AppColors.primary : AppColors.textMuted,
            ),
            title: Text(
              b,
              style: TextStyle(
                fontWeight: widget.currentValue == b ? FontWeight.w700 : FontWeight.normal,
                color: widget.currentValue == b ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            trailing: widget.currentValue == b
                ? Icon(Icons.check, color: AppColors.primary)
                : null,
            onTap: () {
              widget.onSelect(b);
              Navigator.pop(context);
            },
          ),
      ],
    );
  }
}
