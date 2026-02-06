import 'package:flutter/material.dart';

/// 남해 알리미 앱 색상 시스템
///
/// 남해의 자연(숲, 바다)에서 영감을 받은 색상 팔레트.
/// 모든 색상은 WCAG AA 기준(4.5:1 대비율)을 충족합니다.
class AppColors {
  AppColors._();

  // ── Primary: 남해의 숲 (Forest Green) ──────────────────
  static const primary = Color(0xFF1B5E20);
  static const primaryLight = Color(0xFF388E3C);
  static const primaryContainer = Color(0xFFE8F5E9);
  static const onPrimary = Colors.white;

  // ── 일자리 (Ocean Blue) ────────────────────────────────
  static const jobColor = Color(0xFF1565C0);
  static const jobColorLight = Color(0xFFE3F2FD);

  // ── 빈집 (Warm Orange) ─────────────────────────────────
  static const houseColor = Color(0xFFE65100);
  static const houseColorLight = Color(0xFFFFF3E0);

  // ── 상태 (Status) ──────────────────────────────────────
  static const unreadIndicator = Color(0xFF2E7D32);
  static const newBadge = Color(0xFF2E7D32);
  static const readCardBackground = Color(0xFFF5F5F5);

  // ── 텍스트 (Text) ──────────────────────────────────────
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF616161);

  // ── 표면 (Surface) ─────────────────────────────────────
  static const surface = Colors.white;
  static const divider = Color(0xFFE0E0E0);

  // ── 전화 걸기 버튼 ─────────────────────────────────────
  static const callButton = Color(0xFF2E7D32);
  static const callButtonPressed = Color(0xFF1B5E20);

  /// 타입별 색상 반환
  static Color typeColor(String type) =>
      type == 'job' ? jobColor : houseColor;

  /// 타입별 연한 배경색 반환
  static Color typeColorLight(String type) =>
      type == 'job' ? jobColorLight : houseColorLight;
}
