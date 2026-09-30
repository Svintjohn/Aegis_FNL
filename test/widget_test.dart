import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:aegis_fnl/data/models.dart';
import 'package:aegis_fnl/data/store.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('releasing a milestone moves money into the wallet', () {
    final c = container();
    final store = c.read(storeProvider.notifier);
    final before = c.read(storeProvider).walletBalance;

    // Milestone 1-2 is submitted in the seed data.
    store.releaseMilestone('1', '1-2');

    final project = c.read(storeProvider).project('1')!;
    final milestone = project.milestones.firstWhere((m) => m.id == '1-2');

    expect(milestone.status, MilestoneStatus.released);
    expect(c.read(storeProvider).walletBalance, before + 1250);
  });

  test('a new project starts unfunded and cannot be worked on yet', () {
    final c = container();
    final id = c.read(storeProvider.notifier).createProject(
          title: 'Test build',
          description: 'Something small',
          budget: 2000,
          skills: ['Flutter'],
          milestones: [(title: 'Phase one', amount: 2000)],
        );

    final project = c.read(storeProvider).project(id)!;
    expect(project.status, ProjectStatus.awaitingFunds);
    expect(project.isFunded, isFalse);
  });

  test('opening a case freezes the project', () {
    final c = container();
    c.read(storeProvider.notifier).openCase('1', 'Work does not match the brief');

    expect(c.read(storeProvider).project('1')!.status, ProjectStatus.disputed);
    expect(c.read(storeProvider).cases.length, 1);
  });
}
