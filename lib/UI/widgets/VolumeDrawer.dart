import 'package:flutter/material.dart';
import 'package:mighty_plug_manager/bluetooth/devices/value_formatters/ValueFormatter.dart';

import '../../bluetooth/NuxDeviceControl.dart';
import '../../platform/simpleSharedPrefs.dart';
import 'thickSlider.dart';

const _kBottomDrawerPickHeight = 50.0;
const _kBottomDrawerHiddenPadding = 8.0;

class BottomDrawer extends StatelessWidget {
  final bool isBottomDrawerOpen;
  final Function(bool) onExpandChange;
  final Widget child;

  const BottomDrawer({
    Key? key,
    required this.isBottomDrawerOpen,
    required this.onExpandChange,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final device = NuxDeviceControl.instance().device;
    final drawerHeight = device.fakeMasterVolume ? 110.0 : 60.0;

    return GestureDetector(
      onTap: () {
        onExpandChange(!isBottomDrawerOpen);
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -5) {
          //open
          onExpandChange(true);
        } else if (details.delta.dy > 5) {
          //close
          onExpandChange(false);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _kBottomDrawerPickHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Icon(
              isBottomDrawerOpen
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              size: 24,
              color: Colors.grey,
            ),
          ),
          AnimatedContainer(
            padding: const EdgeInsets.all(_kBottomDrawerHiddenPadding),
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            duration: const Duration(milliseconds: 100),
            height: isBottomDrawerOpen ? drawerHeight : 0,
            child: child,
          ),
        ],
      ),
    );
  }
}

class VolumeSlider extends StatelessWidget {
  final String label;
  const VolumeSlider({Key? key, this.label = "Volume"}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final devControl = NuxDeviceControl.instance();
    return ValueListenableBuilder(
      valueListenable: devControl.masterVolumeNotifier,
      builder: (context, value, child) {
        final device = devControl.device;
        final volumeFormatter = device.fakeMasterVolume
            ? ValueFormatters.percentage
            : device.decibelFormatter!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 44,
              child: ThickSlider(
                activeColor: Colors.blue,
                value: devControl.masterVolume,
                skipEmitting: 3,
                label: label,
                labelFormatter: volumeFormatter.toLabel,
                min: volumeFormatter.min.toDouble(),
                max: volumeFormatter.max.toDouble(),
                handleVerticalDrag: false,
                onChanged: _onVolumeChanged,
                onDragEnd: _onVolumeDragEnd,
              ),
            ),
            if (device.fakeMasterVolume)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Restore volume in all presets",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: devControl.canAdjustRefLevels(-5)
                            ? () => devControl.adjustAllReferenceLevels(-5)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text("-5%"),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: devControl.canAdjustRefLevels(5)
                            ? () => devControl.adjustAllReferenceLevels(5)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text("+5%"),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _onVolumeDragEnd(value) {
    NuxDeviceControl.instance().masterVolume = value;
    if (NuxDeviceControl.instance().device.fakeMasterVolume) {
      SharedPrefs().setValue(
        SettingsKeys.masterVolume,
        NuxDeviceControl.instance().masterVolume,
      );
      NuxDeviceControl.instance().scheduleAutoSave();
    }
  }

  void _onVolumeChanged(value, bool skip) {
    if (!skip) {
      NuxDeviceControl.instance().masterVolume = value;
    }
  }
}
