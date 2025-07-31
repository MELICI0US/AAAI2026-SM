// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

// ignore: unused_import
import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:dart_random_choice/dart_random_choice.dart';
// import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

import 'package:jhg_core/jhg_core.dart';
import './providers.dart';

List<Completer<List<PopularityMetrics>>> completers = [];

void main(List<String> args) async {
  print('${DateTime.now()} running simulator...');
  print('${args[1]}_${args[0]}');

  const timeout = Duration(minutes: 5, seconds: 30);
  const popSize = 100;
  const numGeneCopies = 1;
  const numGens = 200;
  const gamesPerGen = 100;
  const agentsPerGame = 8;
  const roundsPerGame = 30;
  const numTopAgents = 25;

  const numCats = 2;
  final extraAgents = [for (int i = 0; i < numCats; i++) CatAgent.new];

  final int lastSuccessfulGen;
  final String generationFolder;

  if (args[1].contains('hCAB')) {
    generationFolder = 'results_withCats_SChMUSR_notCAB_mixed_noFear_noChat_3';
    lastSuccessfulGen = 199;
  } else {
    generationFolder = 'results_withCats_${args[1]}_${args[0]}';
    lastSuccessfulGen = lastSucccessfulGeneration(generationFolder, numGens);
  }

  // await evolve(
  //     popSize: popSize,
  //     numGeneCopies: numGeneCopies,
  //     generation: lastSuccessfulGen,
  //     numGames: gamesPerGen,
  //     agentsPerGame: agentsPerGame,
  //     roundsPerGame: roundsPerGame,
  //     povertyLine: 0,
  //     varied: false,
  //     chat: args[1].contains('chat'),
  //     useSChMUSR: true,
  //     useFear: args[1].contains('fear'),
  //     generationFolder: generationFolder,
  //     folder: 'evaluation_withCats_SChMUSR_${args[1]}_${args[0]}',
  //     timeout: timeout,
  //     extraAgents: extraAgents,
  //     numTopAgents: numTopAgents);

  // await evolve(
  //     popSize: popSize,
  //     numGeneCopies: numGeneCopies,
  //     generation: lastSuccessfulGen,
  //     numGames: gamesPerGen,
  //     agentsPerGame: agentsPerGame + numCats,
  //     roundsPerGame: roundsPerGame,
  //     povertyLine: 0,
  //     varied: false,
  //     chat: args[1].contains('chat'),
  //     useSChMUSR: true,
  //     useFear: args[1].contains('fear'),
  //     generationFolder: generationFolder,
  //     folder: 'evaluation_SChMUSR_${args[1]}_${args[0]}',
  //     timeout: timeout,
  //     numTopAgents: numTopAgents);

  final hCABGenePools = [
    'gene_99_100_92_0_43_71_95_4_25_61_53_0_26_91_11_80_71_11_42_33_10_47_17_100_80_64_60_71_44_17_98_76_50_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_94_92_0_100_4_4_0_13_74_31_42_10_96_3_32_71_0_50_33_37_76_49_90_15_69_20_71_57_52_69_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_87_94_74_0_97_74_94_71_25_60_48_0_23_92_0_22_70_18_71_32_40_68_12_100_70_84_45_82_32_73_98_25_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_16_95_87_0_100_0_3_4_69_64_56_7_0_14_41_0_65_41_0_85_33_63_20_93_19_69_42_82_60_36_100_45_0_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_49_100_92_0_87_4_95_1_15_61_56_0_0_91_12_0_18_3_42_84_10_52_17_98_66_68_42_70_62_12_58_76_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_11_59_16_0_100_2_7_5_4_60_56_10_0_95_0_1_71_24_50_35_42_75_20_0_15_69_19_75_79_19_99_49_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_92_0_75_6_0_1_44_63_55_0_8_47_15_7_32_7_36_85_27_31_40_93_23_26_44_90_13_70_82_46_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_89_0_33_2_47_6_13_63_56_0_0_14_0_0_71_9_45_55_55_74_15_89_15_87_39_90_56_17_76_21_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_100_92_0_87_0_95_1_15_61_56_0_0_91_12_0_71_3_42_84_10_52_17_98_66_68_42_71_62_17_58_76_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_82_76_0_93_3_1_94_9_80_14_0_0_93_11_2_74_23_0_35_25_63_76_95_23_69_64_75_79_73_99_49_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_99_94_92_0_100_4_6_1_76_26_81_42_23_96_0_32_71_7_70_33_23_76_49_90_19_69_20_71_57_52_94_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_10_94_84_0_100_6_47_5_15_48_55_42_0_22_0_0_71_7_0_85_35_74_22_90_75_69_20_35_0_22_81_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_9_57_89_0_88_0_6_6_18_63_56_0_3_14_1_0_71_9_42_14_31_72_15_89_15_87_20_90_56_49_83_26_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_100_77_0_33_2_5_1_10_60_54_0_34_96_14_10_71_88_36_25_16_52_55_95_66_34_20_90_62_83_67_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_8_56_11_0_95_4_92_5_9_74_12_1_45_96_85_4_71_0_42_35_36_76_39_0_15_69_8_75_60_57_85_23_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_89_0_33_2_47_6_13_63_56_0_0_14_0_0_71_9_45_55_55_74_15_89_15_87_39_90_56_17_76_21_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_5_92_0_33_3_47_5_13_76_55_0_17_96_0_4_71_9_65_35_55_74_60_88_22_87_39_90_61_90_65_50_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_94_93_0_91_6_1_5_9_53_52_0_17_96_0_4_84_23_4_84_25_57_10_100_23_87_37_75_79_17_99_26_53_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_92_0_33_2_23_2_13_54_55_0_8_96_0_7_49_3_48_69_55_74_20_95_77_87_39_86_63_55_65_56_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_91_88_0_93_7_93_91_9_78_56_0_11_43_11_59_1_44_45_29_28_57_20_95_47_87_86_96_79_34_83_15_45_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_5_92_0_33_3_47_5_13_76_55_0_17_96_0_4_71_9_65_35_55_74_60_88_22_87_39_90_61_90_65_50_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_99_10_0_22_4_5_4_24_76_52_0_0_14_14_2_59_23_0_85_16_71_8_90_66_68_20_36_29_36_25_46_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_89_0_33_2_47_6_13_63_56_0_0_14_0_0_71_9_45_55_55_74_15_89_15_87_39_90_56_17_76_21_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_15_94_78_0_50_4_94_95_78_51_7_0_21_96_39_52_76_71_0_33_34_76_54_100_68_71_54_35_48_30_98_15_45_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_91_88_0_93_7_93_91_9_78_56_0_11_43_11_59_1_44_45_29_28_57_20_95_47_87_86_96_79_34_83_15_45_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_57_29_0_91_3_94_0_16_61_18_0_3_93_12_0_84_9_42_31_72_54_95_100_66_68_73_71_66_17_24_46_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_10_83_64_0_28_0_47_5_12_48_52_63_0_41_1_0_71_7_0_85_35_74_22_100_75_69_25_90_0_22_83_38_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_59_16_0_100_2_7_1_71_70_56_10_0_95_0_2_65_24_50_35_23_57_14_89_53_69_19_75_60_19_99_33_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_25_11_0_91_6_1_13_9_68_52_10_17_96_14_2_71_3_0_25_25_57_10_100_63_33_37_35_62_32_63_46_53_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_13_100_76_0_75_2_47_1_25_62_56_0_0_95_3_3_32_46_0_51_54_68_56_89_15_68_52_60_56_75_93_47_80_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_10_94_84_0_100_6_47_5_15_48_55_42_0_22_0_0_71_7_0_85_35_74_22_90_75_69_20_35_0_22_81_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_94_92_0_100_4_4_0_13_74_31_42_10_96_3_32_71_0_50_33_37_76_49_90_15_69_20_71_57_52_69_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_77_0_88_7_23_1_17_54_14_1_41_93_0_7_32_88_15_14_16_57_55_34_77_29_20_79_66_32_83_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_58_29_5_91_7_4_3_13_53_54_0_0_96_0_0_84_9_50_84_33_75_13_89_66_29_65_81_57_19_76_28_80_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_92_92_0_77_5_5_1_8_77_56_5_34_14_0_7_68_3_48_69_35_52_20_95_16_89_42_35_62_52_99_56_44_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_100_89_0_100_3_94_1_16_61_14_0_0_91_12_0_32_55_42_31_34_54_94_98_66_68_20_79_66_17_24_46_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_94_77_34_100_4_23_1_10_59_14_0_41_93_0_7_32_88_50_15_34_61_55_100_16_69_20_79_65_29_21_42_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_82_76_0_93_3_1_94_9_80_14_0_0_93_11_2_74_23_0_35_25_63_76_95_23_69_64_75_79_73_99_49_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_57_89_0_36_4_47_1_17_63_56_0_0_90_3_0_32_0_40_55_23_71_56_89_15_68_36_92_56_73_76_78_80_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_99_11_74_0_19_2_47_0_76_78_55_0_23_96_0_2_91_20_0_35_31_63_15_96_19_84_34_90_0_43_81_49_47_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_56_99_16_0_97_7_94_37_69_54_54_0_2_97_0_0_67_42_15_86_14_57_16_90_66_29_20_82_3_19_78_12_58_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_100_81_0_100_6_95_1_15_61_56_0_0_95_12_0_68_9_42_84_10_52_40_15_66_29_20_71_56_20_58_15_80_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_100_57_77_0_19_2_6_5_32_75_56_47_2_97_1_0_71_20_0_85_23_72_52_96_19_68_34_82_57_52_94_26_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_99_10_0_22_4_5_4_24_76_52_0_0_14_14_2_59_23_0_85_16_71_8_90_66_68_20_36_29_36_25_46_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_94_92_0_100_4_4_0_13_74_31_42_10_96_3_32_71_0_50_33_37_76_49_90_15_69_20_71_57_52_69_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_94_89_0_22_5_5_1_13_53_13_1_8_96_18_1_64_23_48_72_31_86_56_100_50_69_20_35_63_52_83_31_5_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_45_99_78_0_75_3_5_37_69_69_59_2_2_92_17_0_91_4_42_69_14_59_5_98_25_87_42_82_86_17_100_12_62_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_87_94_74_0_97_74_94_71_25_60_48_0_23_92_0_22_70_18_71_32_40_68_12_100_70_84_45_82_32_73_98_25_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_88_94_0_95_4_94_3_13_74_12_1_25_14_3_0_20_0_50_69_41_61_20_100_80_87_21_18_29_75_25_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_99_72_0_100_7_5_37_69_21_54_13_2_97_17_0_67_42_42_86_14_52_16_90_66_29_57_82_86_19_78_12_58_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_99_76_0_33_2_90_1_69_78_47_0_0_95_11_2_72_3_0_82_32_57_44_95_57_68_52_82_83_73_83_38_45_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_99_94_92_0_100_4_6_1_76_26_81_42_23_96_0_32_71_7_70_33_23_76_49_90_19_69_20_71_57_52_94_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_57_89_0_95_2_47_4_69_64_56_0_0_14_0_0_65_9_45_55_55_71_20_93_19_68_42_94_60_36_100_21_0_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_99_11_74_0_19_2_47_0_76_78_55_0_23_96_0_2_91_20_0_35_31_63_15_96_19_84_34_90_0_43_81_49_47_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_96_99_77_1_47_8_23_4_17_54_14_1_2_93_0_7_32_8_19_14_16_52_55_89_77_29_20_79_66_19_78_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_100_77_0_33_2_5_1_10_60_54_0_34_96_14_10_71_88_36_25_16_52_55_95_66_34_20_90_62_83_67_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_33_54_76_0_87_0_23_16_15_61_56_0_0_96_12_43_49_3_68_31_10_52_14_98_62_10_48_71_51_81_58_35_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_94_77_34_100_4_23_1_10_59_14_0_41_93_0_7_32_88_50_15_34_61_55_100_16_69_20_79_65_29_21_42_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_99_94_92_0_100_4_6_1_76_26_81_42_23_96_0_32_71_7_70_33_23_76_49_90_19_69_20_71_57_52_94_30_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_37_96_29_0_73_6_5_1_69_57_11_0_10_76_15_0_73_0_45_83_9_72_16_98_53_29_47_82_57_52_81_38_62_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_99_10_0_22_4_5_4_24_76_52_0_0_14_14_2_59_23_0_85_16_71_8_90_66_68_20_36_29_36_25_46_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_100_89_0_100_3_94_1_16_61_14_0_0_91_12_0_32_55_42_31_34_54_94_98_66_68_20_79_66_17_24_46_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_8_56_11_0_95_4_92_5_9_74_12_1_45_96_85_4_71_0_42_35_36_76_39_0_15_69_8_75_60_57_85_23_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_57_89_0_95_2_47_4_69_64_56_0_0_14_0_0_65_9_45_55_55_71_20_93_19_68_42_94_60_36_100_21_0_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_87_0_77_2_23_8_85_54_56_1_8_14_16_7_68_3_48_69_33_52_20_95_77_89_20_33_70_52_100_56_1_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_8_56_11_0_95_4_92_5_9_74_12_1_45_96_85_4_71_0_42_35_36_76_39_0_15_69_8_75_60_57_85_23_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_96_84_0_97_7_92_3_17_71_14_10_23_92_0_22_32_36_45_85_40_57_49_100_70_29_20_84_32_19_81_39_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_99_11_74_0_19_2_47_0_76_78_55_0_23_96_0_2_91_20_0_35_31_63_15_96_19_84_34_90_0_43_81_49_47_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_54_92_0_75_0_47_0_24_76_52_0_0_14_64_4_59_23_0_85_23_75_13_90_26_68_65_66_29_36_25_21_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_94_81_0_100_6_23_6_75_50_56_14_0_14_0_0_64_46_67_33_41_74_16_89_15_87_20_90_62_19_76_38_27_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_8_100_89_0_87_0_2_1_69_53_51_0_1_91_0_0_69_3_42_84_37_50_17_98_66_68_52_15_62_17_58_76_47_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_96_99_77_1_47_8_23_4_17_54_14_1_2_93_0_7_32_8_19_14_16_52_55_89_77_29_20_79_66_19_78_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_57_89_0_95_2_47_4_69_64_56_0_0_14_0_0_65_9_45_55_55_71_20_93_19_68_42_94_60_36_100_21_0_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_21_100_92_0_75_6_90_1_15_63_56_0_0_14_0_4_60_7_36_80_27_31_17_100_53_87_44_90_77_17_82_18_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_92_92_0_77_5_5_1_8_77_56_5_34_14_0_7_68_3_48_69_35_52_20_95_16_89_42_35_62_52_99_56_44_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_8_100_89_0_87_0_2_1_69_53_51_0_1_91_0_0_69_3_42_84_37_50_17_98_66_68_52_15_62_17_58_76_47_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_77_0_88_7_23_1_17_54_14_1_41_93_0_7_32_88_15_14_16_57_55_34_77_29_20_79_66_32_83_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_14_96_84_0_97_7_92_3_17_71_14_10_23_92_0_22_32_36_45_85_40_57_49_100_70_29_20_84_32_19_81_39_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_100_81_0_100_6_95_1_15_61_56_0_0_95_12_0_68_9_42_84_10_52_40_15_66_29_20_71_56_20_58_15_80_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_9_57_77_0_88_0_6_5_32_58_56_10_3_14_1_4_71_7_42_14_35_72_55_88_10_68_20_66_57_48_83_26_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_77_0_88_7_23_1_17_54_14_1_41_93_0_7_32_88_15_14_16_57_55_34_77_29_20_79_66_32_83_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_10_83_64_0_28_0_47_5_12_48_52_63_0_41_1_0_71_7_0_85_35_74_22_100_75_69_25_90_0_22_83_38_6_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_97_94_89_0_100_4_48_13_13_53_56_0_0_95_0_2_68_0_36_33_31_70_15_88_50_29_20_81_57_23_79_46_80_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_8_56_11_0_95_4_92_5_9_74_12_1_45_96_85_4_71_0_42_35_36_76_39_0_15_69_8_75_60_57_85_23_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_16_94_87_0_100_4_23_1_69_64_56_0_3_14_0_7_65_86_0_15_34_61_55_93_19_69_42_82_65_36_22_42_78_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_94_89_0_22_4_19_0_13_53_13_0_0_96_0_2_64_0_41_72_31_76_15_88_50_69_20_35_63_81_83_31_5_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_54_89_0_95_2_1_3_69_64_56_0_0_14_0_0_65_93_45_55_59_71_56_52_82_68_40_25_32_42_86_21_85_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_100_92_0_75_2_0_1_17_71_26_0_8_43_5_7_71_46_31_85_10_57_17_93_77_66_44_77_13_72_63_46_82_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_37_96_29_0_73_6_5_1_69_57_11_0_10_76_15_0_73_0_45_83_9_72_16_98_53_29_47_82_57_52_81_38_62_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_99_57_74_0_19_2_47_1_76_75_55_2_23_97_0_2_91_20_0_85_23_59_8_96_19_55_34_82_57_52_94_26_84_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_97_59_16_0_100_9_48_1_15_63_56_8_0_14_0_1_68_5_36_80_27_74_20_100_53_29_20_82_56_19_82_18_49_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_100_77_0_33_2_5_1_10_60_54_0_34_96_14_10_71_88_36_25_16_52_55_95_66_34_20_90_62_83_67_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_57_77_0_88_7_23_1_17_54_14_1_41_93_0_7_32_88_15_14_16_57_55_34_77_29_20_79_66_32_83_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_94_89_0_22_5_5_1_13_53_13_1_8_96_18_1_64_23_48_72_31_86_56_100_50_69_20_35_63_52_83_31_5_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_54_89_0_95_2_1_3_69_64_56_0_0_14_0_0_65_93_45_55_59_71_56_52_82_68_40_25_32_42_86_21_85_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_100_77_0_33_2_23_1_13_60_14_0_45_96_0_10_32_88_36_35_23_74_55_34_77_69_18_90_0_32_83_46_83_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_12_88_76_0_32_2_99_3_13_78_12_0_25_95_3_2_72_3_0_69_41_57_20_95_80_87_21_82_29_74_83_30_45_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_46_92_92_0_77_5_5_1_8_77_56_5_34_14_0_7_68_3_48_69_35_52_20_95_16_89_42_35_62_52_99_56_44_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_94_89_0_62_6_6_0_17_63_56_0_12_96_0_0_71_9_63_12_31_72_14_89_15_87_20_90_56_51_83_26_85_0_0_0_0_0_0_0_0_0_0_0_0',
    'gene_95_25_11_0_91_6_1_13_9_68_52_10_17_96_14_2_71_3_0_25_25_57_10_100_63_33_37_35_62_32_63_46_53_0_0_0_0_0_0_0_0_0_0_0_0',
  ];

  // await evolve(
  //     popSize: popSize,
  //     numGeneCopies: numGeneCopies,
  //     generation: lastSuccessfulGen,
  //     numGames: gamesPerGen,
  //     agentsPerGame: 5,
  //     roundsPerGame: roundsPerGame,
  //     povertyLine: 0,
  //     varied: false,
  //     chat: args[1].contains('chat'),
  //     useSChMUSR: true,
  //     useFear: args[1].contains('fear'),
  //     generationFolder: generationFolder,
  //     folder: 'evaluation_withHCABs_SChMUSR_${args[1]}_${args[0]}',
  //     timeout: timeout,
  //     extraAgentGenePool: hCABGenePools,
  //     numExtraAgents: 5,
  //     numTopAgents: numTopAgents);

  // await evolve(
  //     popSize: popSize,
  //     numGeneCopies: numGeneCopies,
  //     generation: lastSuccessfulGen,
  //     numGames: gamesPerGen,
  //     agentsPerGame: 4,
  //     roundsPerGame: roundsPerGame,
  //     povertyLine: 0,
  //     varied: false,
  //     chat: args[1].contains('chat'),
  //     useSChMUSR: true,
  //     useFear: args[1].contains('fear'),
  //     generationFolder: generationFolder,
  //     folder: 'evaluation_withHCABsAndCats_SChMUSR_${args[1]}_${args[0]}',
  //     timeout: timeout,
  //     extraAgents: extraAgents,
  //     extraAgentGenePool: hCABGenePools,
  //     numExtraAgents: 4,
  //     numTopAgents: numTopAgents);

  // await evolve(
  //     popSize: popSize,
  //     numGeneCopies: numGeneCopies,
  //     generation: lastSuccessfulGen,
  //     numGames: gamesPerGen,
  //     agentsPerGame: 0,
  //     roundsPerGame: roundsPerGame,
  //     povertyLine: 0,
  //     varied: false,
  //     chat: args[1].contains('chat'),
  //     useSChMUSR: true,
  //     useFear: args[1].contains('fear'),
  //     generationFolder: generationFolder,
  //     folder: 'evaluation_withCats_hCAB_${args[0]}',
  //     timeout: timeout,
  //     extraAgents: extraAgents,
  //     extraAgentGenePool: hCABGenePools,
  //     numExtraAgents: 8,
  //     numTopAgents: 0);

  // await evolve(
  //     popSize: popSize,
  //     numGeneCopies: numGeneCopies,
  //     generation: lastSuccessfulGen,
  //     numGames: gamesPerGen,
  //     agentsPerGame: 0,
  //     roundsPerGame: roundsPerGame,
  //     povertyLine: 0,
  //     varied: false,
  //     chat: args[1].contains('chat'),
  //     useSChMUSR: true,
  //     useFear: args[1].contains('fear'),
  //     generationFolder: generationFolder  ,
  //     folder: 'evaluation_hCAB_${args[0]}',
  //     timeout: timeout,
  //     extraAgentGenePool: hCABGenePools,
  //     numExtraAgents: 10,
  //     numTopAgents: 0);

  await evolve(
      popSize: popSize,
      numGeneCopies: 1,
      generation: lastSuccessfulGen,
      numGames: gamesPerGen,
      agentsPerGame: 8,
      roundsPerGame: roundsPerGame,
      povertyLine: 0,
      varied: false,
      chat: args[1].contains('chat'),
      useSChMUSR: false,
      useFear: args[1].contains('fear'),
      generationFolder: generationFolder,
      folder: 'evaluation_withCats_2eCAB_${args[0]}',
      timeout: timeout,
      extraAgents: extraAgents,
      numTopAgents: numTopAgents);

  await evolve(
      popSize: popSize,
      numGeneCopies: 1,
      generation: lastSuccessfulGen,
      numGames: gamesPerGen,
      agentsPerGame: 10,
      roundsPerGame: roundsPerGame,
      povertyLine: 0,
      varied: false,
      chat: args[1].contains('chat'),
      useSChMUSR: false,
      useFear: args[1].contains('fear'),
      generationFolder: generationFolder,
      folder: 'evaluation_2eCAB_${args[0]}',
      timeout: timeout,
      numTopAgents: numTopAgents);

  print('${DateTime.now()} simulation complete');

  exit(0);
}

int lastSucccessfulGeneration(String folder, int numGenerations) {
  try {
    final files = Directory('./$folder/generations').listSync()
      ..sort((a, b) {
        final aNum =
            int.parse(RegExp(r'_(\d+)\.csv').firstMatch(a.path)!.group(1)!);
        final bNum =
            int.parse(RegExp(r'_(\d+)\.csv').firstMatch(b.path)!.group(1)!);
        return aNum.compareTo(bNum);
      });

    final lastSuccessfulGen = int.parse(
        RegExp(r'_(\d+)\.csv').firstMatch(files.last.path)?.group(1) ?? '0');

    print('Evaluating generation $lastSuccessfulGen');

    return lastSuccessfulGen;
  } catch (_) {
    return 0;
  }
}

Future<void> initialize() async {
  const dir = '/home/melissa/Documents/.jhg_data/preprod/emulator';
  final d = Directory(dir);
  if (!d.existsSync()) {
    d.createSync(recursive: true);
  }
  setupDartFirebaseStorage(d);

  // await initFirebase();
}

Future<void> evolve({
  required int popSize,
  required int numGeneCopies,
  required int generation,
  required int numGames,
  required int agentsPerGame,
  required int roundsPerGame,
  required double povertyLine,
  required bool varied,
  required bool chat,
  required bool useSChMUSR,
  required bool useFear,
  required String generationFolder,
  required String folder,
  Duration timeout = const Duration(minutes: 2, seconds: 30),
  List<Agent Function(AutoDisposeProviderRef<dynamic>)>? extraAgents,
  List<String>? extraAgentGenePool,
  int? numExtraAgents,
  required int numTopAgents,
}) async {
  final start = DateTime.now();

  var theGenePools = <GeneMetrics>[];

  final file = File('./$generationFolder/generations/gen_$generation.csv');
  if (!file.existsSync()) {
    throw Exception('File does not exist: ${file.path}');
  }

  final csv =
      const CsvToListConverter().convert(file.readAsStringSync(), eol: '\n');

  for (var j = 0; j < popSize; j++) {
    final gene = csv[j][0] as String;
    final count = csv[j][1] as int;
    final relFit = csv[j][2] as double;
    final absFit = csv[j][3] as double;
    final metric = GeneMetrics(gene,
        count: count, absoluteFitness: absFit, relativeFitness: relFit);
    theGenePools.add(metric);
  }

  // Pick the top agents
  theGenePools.sort(compareEm);
  theGenePools = theGenePools.sublist(0, numTopAgents);

  completers.clear();

  // let's do this for each game
  for (var game = 0; game < numGames; game++) {
    final agents = <GeneMetrics>[];
    final plyrIdxs = <int>[];

    // time to pick individuals from the gene pools
    for (var i = 0; i < agentsPerGame; i++) {
      plyrIdxs.add(Random().nextInt(numTopAgents));
      agents.add(theGenePools[plyrIdxs[i]]);
    }

    // record who the players were
    await Directory('./$folder/players').create(recursive: true);
    final resultsFile = File('./$folder/players/players_$game.txt');

    if (resultsFile.existsSync()) {
      await resultsFile.delete();
    }
    for (final player in plyrIdxs) {
      await resultsFile.writeAsString('$player ${theGenePools[player].gene}\n',
          mode: FileMode.append);
    }

    completers.add(Completer<List<PopularityMetrics>>());

    // create port to listen for popularity metrics from the isolate
    final port = ReceivePort();
    port.listen((pMetrics) {
      if (pMetrics is List<PopularityMetrics>) {
        for (var i = 0; i < agentsPerGame; i++) {
          final gene = theGenePools[plyrIdxs[i]].gene;
          final pmGene = pMetrics[i].gene;
          if (gene != pmGene) {
            print('gene mismatch: $gene != $pmGene');
          }

          //Update fitness
          theGenePools[plyrIdxs[i]].count++;
          theGenePools[plyrIdxs[i]].absoluteFitness +=
              (pMetrics[i].avePop + pMetrics[i].endPop) / 2.0;
          theGenePools[plyrIdxs[i]].relativeFitness += pMetrics[i].relPop;
        }

        completers[game].complete(pMetrics);
        port.close();
      }
    });

    // spawn isolate to run game
    final isolate = runIsolate(
        theGenePools,
        plyrIdxs,
        numGeneCopies,
        agentsPerGame,
        roundsPerGame,
        game,
        chat,
        port.sendPort,
        folder,
        extraAgents,
        extraAgentGenePool,
        numExtraAgents,
        useSChMUSR,
        useFear);

    // kill the isolate if it takes too long
    unawaited(completers[game].future.timeout(timeout, onTimeout: () async {
      print('Isolate timed out on $game');
      (await isolate).kill(priority: Isolate.immediate);
      print('Isolate killed');
      if (!completers[game].isCompleted) {
        completers[game].complete([]);
      }
      return [];
    }));
    //END isolate experiment
  }

  // wait for all games in this generation to finish
  for (final completer in completers) {
    await completer.future;
  }

  for (var i = 0; i < numTopAgents; i++) {
    if (theGenePools[i].count > 0) {
      theGenePools[i].relativeFitness /= theGenePools[i].count;
      theGenePools[i].absoluteFitness /= theGenePools[i].count;
    } else {
      theGenePools[i].relativeFitness = 0.0;
      theGenePools[i].absoluteFitness = 0.0;
    }
  }
  theGenePools.sort(compareEm);

  await writeGenerationResults(
      theGenePools, numTopAgents, agentsPerGame, folder);

  final totalTime = DateTime.now().difference(start);

  print(
      '${DateTime.now()} time taken to run evaluation with $numGames games: $totalTime\n');
  // write this to the log file
  await Directory('./$folder/logs').create(recursive: true);
  final logFile = File('./$folder/logs/time_log.txt');
  await logFile.writeAsString(
      '${DateTime.now()} time taken to run evaluation with $numGames games: $totalTime\n',
      mode: FileMode.append);
}

Future<Isolate> runIsolate(
  List<GeneMetrics> theGenePools,
  List<int> plyrIdxs,
  int numGeneCopies,
  int agentsPerGame,
  int roundsPerGame,
  int game,
  bool chat,
  SendPort sendPort,
  String folder,
  List<Agent Function(AutoDisposeProviderRef)>? extraAgents,
  List<String>? extraAgentGenePool,
  int? numExtraAgents,
  bool useSChMUSR,
  bool useFear,
) async {
  await Directory('./$folder/logs').create(recursive: true);
  final logFile = File('./$folder/logs/gameLog_$game.txt');
  if (logFile.existsSync()) {
    await logFile.delete();
  }

  final isolate = Isolate.spawn<SendPort>((sendPort) async {
    final List<AutoDisposeProvider<GeneAgent>> agents;

    if (useSChMUSR) {
      agents = [
        for (int i = 0; i < agentsPerGame; i++)
          Provider.autoDispose(
              (ref) => ChatterBotAgent(ref,
                  genes: theGenePools[plyrIdxs[i]].gene,
                  numGeneCopies: numGeneCopies,
                  useFear: useFear,
                  logfile: logFile),
              dependencies: [...agentProviders])
      ];
    } else {
      agents = [
        for (int i = 0; i < agentsPerGame; i++)
          Provider.autoDispose(
              (ref) => GeneAgent(
                    ref,
                    genes: theGenePools[plyrIdxs[i]].gene,
                    numGeneCopies: numGeneCopies,
                  ),
              dependencies: [...agentProviders])
      ];
    }

    assert(extraAgents == null || extraAgentGenePool == null,
        'Cannot have both extraAgents and extraAgentGenePool');
    assert(
        (extraAgentGenePool != null && numExtraAgents != null) ||
            extraAgentGenePool == null,
        'extraAgentGenePool and numExtraAgents must be provided together');

    final extraAgentProviders = <AutoDisposeProvider<Agent>>[];

    if (extraAgents != null) {
      extraAgentProviders.addAll([
        for (final agent in extraAgents)
          Provider.autoDispose(agent, dependencies: [...agentProviders])
      ]);
    }
    if (extraAgentGenePool != null) {
      extraAgentProviders.addAll([
        for (int i = 0; i < numExtraAgents!; i++)
          Provider.autoDispose(
              (ref) => GeneAgent(
                    ref,
                    genes: randomChoice(extraAgentGenePool),
                    numGeneCopies: numGeneCopies,
                  ),
              dependencies: [...agentProviders])
      ]);
    }

    final results = await playGame(
        agents,
        agentsPerGame + (extraAgents?.length ?? 0),
        roundsPerGame,
        game,
        {}, // `TODO: initialPopularities
        0,
        false,
        chat,
        folder,
        extraAgentProviders,
        useSChMUSR);

    Isolate.exit(sendPort, results);
  }, sendPort);

  return isolate;
}

List<PopularityMetrics> getAlgorithmTestData(List<String> genes) {
  final metrics = <PopularityMetrics>[];
  for (final gene in genes) {
    final values = gene.split('_');
    values.removeAt(0);
    final fitness = values.map(int.parse).toList().sum.toDouble();
    final metric = PopularityMetrics(gene, fitness, fitness, fitness);
    metrics.add(metric);
  }

  var sumOfPops = 0.0;
  for (var i = 0; i < genes.length; i++) {
    sumOfPops += metrics[i].avePop;
  }
  for (var i = 0; i < genes.length; i++) {
    metrics[i].relPop = metrics[i].avePop / sumOfPops;
  }

  return metrics;
}

Future<void> writeGenerationResults(List<GeneMetrics> theGenePools, int popSize,
    int agentsPerGame, String folder) async {
  await Directory('./$folder/generations').create(recursive: true);
  final resultsFile = File('./$folder/evaluation.csv');
  if (resultsFile.existsSync()) {
    await resultsFile.delete();
  }

  for (var i = 0; i < popSize; i++) {
    await resultsFile.writeAsString(
        '${theGenePools[i].gene},${theGenePools[i].count},${theGenePools[i].relativeFitness},${theGenePools[i].absoluteFitness},${getCSVFormattedGeneString(theGenePools[i].gene)}\n',
        mode: FileMode.append);
  }

  if (!resultsFile.existsSync()) {
    resultsFile.createSync();
  }
}

String getCSVFormattedGeneString(String gene) {
  final genes = gene.split('_');
  genes.removeAt(0);
  return genes.join(',');
}

int compareEm(GeneMetrics a, GeneMetrics b) {
  return a.absoluteFitness.compareTo(b.absoluteFitness);
}

Future<List<PopularityMetrics>> playGame(
  List<AutoDisposeProvider<GeneAgent>> agents,
  int numPlayers,
  int numRounds,
  int gamer,
  Map<String, double> initialPopularities,
  double povertyLine,
  bool forcedRandom,
  bool chat,
  String folder,
  List<AutoDisposeProvider<Agent>>? extraAgents,
  bool useSChMUSR,
) async {
  await initialize();
  // final startItr = DateTime.now();

  await Directory('./$folder/gameInfos').create(recursive: true);
  final resultsFile = File('./$folder/gameInfos/gameInfo_$gamer.json');

  await resultsFile.writeAsString('game started');

  //Set up game
  final gameParams = GameParams(
    lengthOfRound: const Duration(seconds: 30),
    gameEndCriteria: GameEndCriteria.rounds(low: numRounds, high: numRounds),
    popularityFunctionParams: PopularityFunctionParams(
      povertyLine: povertyLine,
    ),
    chatType: chat ? ChatType.direct : ChatType.none,
  );

  final gameService = InAppGameService();

  //TODO: get game setup working so we can use different initial popularities
  // final gameSetup = await createGameSetup(numRounds, povertyLine, initialPopularities);

  // final lobby = gameService.lobbyListen(
  //     LobbyRequest(gameId: createGameResponse.gameId, playerId: createGameResponse.playerId));

  // final listener = lobby.listen((event) async {
  //   if (event.lobby.numPlayers > 1 && !event.lobby.gameStarted) {
  //     final startGameResponse = await gameService.startGame(StartGameRequest(
  //       gameId: createGameResponse.gameId,
  //       playerId: createGameResponse.playerId,
  //     ));
  //     print(startGameResponse);
  //     completer.complete();
  //   }
  // });

  // final gameSetupResponse = await gameService.setGameSetup(SetGameSetupRequest(
  //     gameId: createGameResponse.gameId,
  //     playerId: createGameResponse.playerId,
  //     setup: const GameSetup(name: 'Simulation', id: '-NtqCURT9ZcBY7lfXYw2')));
  // print(gameSetupResponse);

  final ais = <ProviderContainer>[];
  final subs = <ProviderSubscription<GeneAgent>>[];

  final roundService = InAppRoundService();
  final dataService = InAppDataService();
  // const chatService = InAppChatService();

  //Create game and set gameParams
  final createGameResponse = await gameService.createGame(
      const CreateGameRequest(isObserver: true, playerName: 'Observer'));
  await gameService.updateGameParams(UpdateGameParamsRequest(
      gameId: createGameResponse.gameId,
      playerId: createGameResponse.playerId,
      params: gameParams));

  //Add gene agents to game
  for (var p = 0; p < agents.length; p++) {
    ais.add(ProviderContainer(
      overrides: [
        multiplayerIdProvider.overrideWithValue(100 + p),
        gameServiceProvider.overrideWithValue(gameService),
        isAdminProvider.overrideWith((ref) => false),
        isObserverProvider.overrideWith((ref) => false),
        ...persistenceTestOverrides
      ],
    ));
    subs.add(ais[p].listen(agents[p], (_, __) {}));
    final agent = subs[p].read();

    final agentName =
        useSChMUSR ? 'Agent with genes ${agent.genes}' : 'Gene ${agent.genes}';

    await agent.joinAndPlay(createGameResponse.gameCode, name: agentName);
  }

  //Add extra agents to game
  final extraSubs = <ProviderSubscription<Agent>>[];

  if (extraAgents != null) {
    for (var p = 0; p < extraAgents.length; p++) {
      ais.add(ProviderContainer(
        overrides: [
          multiplayerIdProvider.overrideWithValue(100 + p + agents.length),
          gameServiceProvider.overrideWithValue(gameService),
          isAdminProvider.overrideWith((ref) => false),
          isObserverProvider.overrideWith((ref) => false),
          ...persistenceTestOverrides
        ],
      ));
      extraSubs.add(ais[p + agents.length].listen(extraAgents[p], (_, __) {}));
      final agent = extraSubs[p].read();
      await agent.joinAndPlay(createGameResponse.gameCode);
    }
  }

  //Start game
  await gameService.startGame(StartGameRequest(
      gameId: createGameResponse.gameId,
      playerId: createGameResponse.playerId));

  final gameCompleter = Completer<List<PopularityMetrics>>();

  // final watchChat = chatService.watchChat(WatchChatRequest(
  //     gameId: createGameResponse.gameId, playerId: createGameResponse.playerId, isObserver: true));

  // var chatCount = 0;
  // watchChat.listen((event) async {
  //   chatCount++;
  //   if (chatCount % 10 == 0) {
  //     final gameInfo =
  //         await dataService.download(DownloadRequest(gameCodes: [createGameResponse.gameCode]));

  //     await Directory('./results/gameInfos/gen_$gener').create(recursive: true);
  //     final resultsFile =
  //         File('./results/gameInfos/gen_$gener/gameInfo_${gener}_$gamer.json');

  //     await resultsFile.writeAsString(
  //       jsonEncode(gameInfo),
  //     );
  //   }
  // });

  //Watch for end of game and write the game info when completed
  final watchGame = roundService.watchGame(WatchGameRequest(
      gameId: createGameResponse.gameId,
      playerId: createGameResponse.playerId,
      isObserver: true));
  watchGame.listen((event) async {
    if (event.roundInfo.round % 5 == 0) {
      //  print('round ${event.roundInfo.round}');
    }
    if (event.roundInfo.status.isGameOver) {
      // print('Game over');

      final gameInfo = await dataService
          .download(DownloadRequest(gameCodes: [createGameResponse.gameCode]));

      await Directory('./$folder/gameInfos').create(recursive: true);
      final resultsFile = File('./$folder/gameInfos/gameInfo_$gamer.json');

      await resultsFile.writeAsString(
        jsonEncode(gameInfo),
      );

      final agentNameToGene = [
        for (final sub in subs) (sub.read().myPlayerName, sub.read().genes!)
      ];

      final extraAgentNames = [
        for (final sub in extraSubs) sub.read().myPlayerName
      ];

      final lastRound = event.roundInfo.round - 1;
      final popularityMetrics = getPopularityMetrics(
          gameInfo, numPlayers, lastRound, agentNameToGene, extraAgentNames);

      gameCompleter.complete(popularityMetrics);
    }
  });

  // ignore: avoid_types_on_closure_parameters
  final pMetrics = await gameCompleter.future.catchError((Object error) {
    throw Exception('Game failed to complete: $error');
  });
  // final itrTime = DateTime.now().difference(startItr);
  // print('time taken: $itrTime');

  return pMetrics;
}

List<PopularityMetrics> getPopularityMetrics(
    DownloadResponse gameInfo,
    int numPlayers,
    int lastRound,
    List<(String, String)> agentNameToGene,
    List<String> extraAgentNames) {
  final pMetrics = <PopularityMetrics>[];
  final game = gameInfo.infos?[0];
  if (game == null) {
    throw Exception("Game info is null. Can't generate popularity metrics.");
  }

  for (final agent in agentNameToGene) {
    final lastRoundString = roundKey(lastRound.toString());

    final avePop =
        game.popularities!.entries.map((e) => e.value[agent.$1]!).average;
    final endPop = game.popularities![lastRoundString]![agent.$1]!;
    final gene = agent.$2;

    pMetrics.add(PopularityMetrics(gene, avePop, endPop, 0));
  }

  //Add pops of the extra agents
  var sumOfPops = 0.0;
  for (final extraAgent in extraAgentNames) {
    final avePop =
        game.popularities!.entries.map((e) => e.value[extraAgent]!).average;

    sumOfPops += avePop;
  }

  //TODO: is this supposed to be calculated with avePop or endPop?

  for (var i = 0; i < pMetrics.length; i++) {
    sumOfPops += pMetrics[i].avePop;
  }
  for (var i = 0; i < pMetrics.length; i++) {
    pMetrics[i].relPop = pMetrics[i].avePop / sumOfPops;
  }

  return pMetrics;
}

//No worky
Future<GameSetup> createGameSetup(
  int numRounds,
  double povertyLine,
  Map<String, double> initialPopularities,
) async {
  //Set up game
  final gameParams = GameParams(
    gameEndCriteria: GameEndCriteria.rounds(low: numRounds, high: numRounds),
    popularityFunctionParams: PopularityFunctionParams(
      povertyLine: povertyLine,
    ),
    chatType: ChatType.direct,
  );

  //Admin service to create game setup
  final adminService =
      FirebaseAdminService(Uri(scheme: 'http', host: 'localhost', port: 8080));
  print('signing in...');
  //TODO: get credentials working
  // final credentials = Credentials.applicationDefault()!;

  // final credentials = await dartFirebaseAuth.createUserWithEmailAndPassword(
  //     email: 'crandallberry.ai@gmail.com', password: 'crandallberrylim');
  final credentials = await dartFirebaseAuth.signInWithEmailAndPassword(
      email: 'crandallberry.ai@gmail.com', password: 'crandallberrylim');
  print('signed in');

  final authId = credentials.user?.uid;

  if (authId == null) {
    throw Exception('authId is null');
  }

  const gameSetup = GameSetup(name: 'simulation game');

  final uploadSetupResponse = await adminService.uploadSetup(UploadSetupRequest(
      authId: authId,
      game: InitialGameInfo(gameParams: gameParams),
      setup: gameSetup));

  if (uploadSetupResponse.success) {
    return gameSetup.copyWith(id: uploadSetupResponse.id);
  } else {
    throw Exception('Failed to upload game setup');
  }
}

class PopularityMetrics {
  PopularityMetrics(this.gene, this.avePop, this.endPop, this.relPop);

  String gene;
  double avePop;
  double endPop;
  double relPop;

  @override
  String toString() {
    return 'PopularityMetrics(avePop: $avePop, endPop: $endPop, relPop: $relPop, gene: $gene)';
  }
}

class GeneMetrics {
  GeneMetrics(this.gene,
      {this.count = 0, this.absoluteFitness = 0, this.relativeFitness = 0});

  String gene;
  int count;
  double absoluteFitness;
  double relativeFitness;

  int get numGenes => gene.split('_').length - 1;
}
