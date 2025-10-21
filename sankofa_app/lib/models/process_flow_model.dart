import 'package:flutter/material.dart';

class ProcessStepModel {
  const ProcessStepModel({
    required this.title,
    required this.description,
    required this.icon,
    this.helper,
    this.badge,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? helper;
  final String? badge;
}

class ProcessFlowModel {
  const ProcessFlowModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.heroAsset,
    required this.expectation,
    required this.steps,
    required this.highlights,
    required this.completionTitle,
    required this.completionDescription,
    this.primaryActionLabel = 'Next Step',
    this.secondaryActionLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final String heroAsset;
  final String expectation;
  final List<ProcessStepModel> steps;
  final List<String> highlights;
  final String completionTitle;
  final String completionDescription;
  final String primaryActionLabel;
  final String? secondaryActionLabel;
}