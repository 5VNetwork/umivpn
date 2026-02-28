import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

Widget getCountryIcon(String countryCode) {
  return SvgPicture(
    height: 24,
    width: 24,
    AssetBytesLoader('assets/icons/flags/${countryCode.toLowerCase()}.svg.vec'),
  );
}
